"""Entry point for `pesto-fetch-bytestreams` CLI helper tool.

This tool outputs lines of the following format:
```
<bytestream-uri>\t<json-encoded-read-response>
```

Example usages:

(Run from project's root directory, `pesto-remote-apis-helpers`.)

```
# Read an explicit list of bytestream URIs
$ uv run pesto-fetch-bytestreams \
    --uri grpc://localhost:8980 \
    bytestream://blobs/477b2a3983637d7633933691800642a388a38e1dd81ebe12304a603dc3b3dfba/226
```

```
# Read bytestream URIs from stdin. This is the form pesto.nvim uses.
$ echo "bytestream://blobs/477b2a3983637d7633933691800642a388a38e1dd81ebe12304a603dc3b3dfba/226" \
    | uv run pesto-fetch-bytestreams \
    --uri grpc://localhost:8980 \
    -
```
"""

import asyncio
import argparse
import logging
import re
import sys
from urllib.parse import urlparse

import grpc
from google.protobuf.json_format import MessageToJson

from pesto.proto.googleapis.google.bytestream import bytestream_pb2
from pesto.proto.googleapis.google.bytestream import bytestream_pb2_grpc

logger = logging.getLogger(__name__)

BYTE_STREAM_URI_PATTERN = re.compile("bytestream://(?P<name>.+)", re.IGNORECASE)

parser = argparse.ArgumentParser(
    prog="pesto-fetch-bytestreams",
    description="Helper tool for pesto.nvim plugin. Downloads byestream resources from remote cache.",
)
parser.add_argument(
    "--uri", help="Address of remote cache (e.g., grpc://localhost:9100)", required=True
)
parser.add_argument(
    "-w",
    "--num-workers",
    nargs="?",
    help="Number of workers downloading byte streams concurrently.",
    default=10,
)
parser.add_argument(
    "-l",
    "--log-file",
    nargs="?",
    help="Log file. If not specified, logs are written to stderr.",
)
parser.add_argument(
    "byte_streams",
    nargs="*",
    help="List of byte stream URIs. If a single '-' is provided then byte streams are read from stdin.",
)


async def add_bytestream_uris(queue, byte_stream_uris):
    if byte_stream_uris[0] == "-":
        logger.info(f"reading byte stream URIs from stdin")
        loop = asyncio.get_event_loop()
        reader = asyncio.StreamReader()
        protocol = asyncio.StreamReaderProtocol(reader)
        await loop.connect_read_pipe(lambda: protocol, sys.stdin)
        while True:
            line = (await reader.readline()).decode("utf-8")
            if not line:
                logger.info(f"done reading URIs from stdin")
                queue.shutdown()
                break
            logger.debug(f"done reading URIs")
            await queue.put(line.strip())
    else:
        for uri in byte_stream_uris:
            await queue.put(uri)
        queue.shutdown()


async def fetch_byte_streams(worker_id, byte_stream_stub, byte_stream_uris):
    while True:
        try:
            uri = await byte_stream_uris.get()
        except asyncio.QueueShutDown as e:
            logger.info(f"[worker={worker_id}] finished")
            break
        logger.info(f"[worker={worker_id}] fetching byte stream {uri}")

        try:
            match = BYTE_STREAM_URI_PATTERN.search(uri)
            if not match:
                raise Exception(
                    f'[worker={worker_id}] failed to parse byte stream URI: "{uri}"'
                )
            request = bytestream_pb2.ReadRequest(
                resource_name="/" + match.group("name")
            )
            async for read_response in byte_stream_stub.Read(request):
                json_string = MessageToJson(read_response, indent=None)
                print(f"{uri}\t{json_string}", flush=True)
                logger.info(f"[worker={worker_id}] fetched byte stream response")
        except Exception as e:
            logger.error(f"[worker={worker_id}] error fetching byte stream {uri}: {e}")

        print(f"{uri}\t", flush=True)
        logger.info(f"[worker={worker_id}] finished fetching byte stream {uri}")


async def async_main():
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO)
    if args.log_file:
        logger.addHandler(logging.FileHandler(args.log_file))
    else:
        logger.addHandler(logging.StreamHandler(stream=sys.stderr))

    if len(args.byte_streams) == 0:
        logger.info("no byte streams to fetch")
        return

    logger.info(f"fetching {len(args.byte_streams)} byte streams")

    logger.info(f"opening channel to {args.uri}")
    try:
        parsed_url = urlparse(args.uri)
        match parsed_url.scheme.lower():
            case "grpc":
                grpc_channel = grpc.aio.insecure_channel(parsed_url.netloc)
            case "grpcs":
                grpc_channel = grpc.aio.insecure_channel(
                    parsed_url.netloc, grpc.ssl_channel_credentials()
                )
            case _:
                raise Exception(f"unsupported url scheme: {parsed_url.scheme}")
    except Exception as e:
        logger.error(f"failed to open channel to {args.uri}")
        logger.critical(e)
        exit(1)
    logger.info(f"successfully opened channel to {args.uri}")

    async with (
        grpc_channel as channel,
        asyncio.TaskGroup() as tg,
    ):
        byte_stream_stub = bytestream_pb2_grpc.ByteStreamStub(channel)

        byte_stream_uris = asyncio.Queue()
        add_uris_task = tg.create_task(
            add_bytestream_uris(byte_stream_uris, args.byte_streams)
        )

        download_tasks = [
            tg.create_task(fetch_byte_streams(i, byte_stream_stub, byte_stream_uris))
            for i in range(0, args.num_workers)
        ]


def main():
    asyncio.run(async_main())


if __name__ == "__main__":
    main()
