from grpc_tools import protoc
import os
from pathlib import Path

current_dir = Path(__file__).parent
src_dir = (current_dir / ".." / "packages" / "proto" / "src").resolve()
proto_dir = src_dir


def main():
    # see: https://github.com/grpc/grpc/blob/master/tools/distrib/python/grpcio_tools/grpc_tools/protoc.py
    proto_files = list(proto_dir.glob("**/*.proto"))
    protoc_args = [
        "grpc_tools.protoc",
        f"--proto_path={proto_dir}",
        f"--python_out={proto_dir}",
        f"--grpc_python_out={proto_dir}",
        *[str(file) for file in proto_files],
    ]
    protoc.main(protoc_args)


if __name__ == "__main__":
    main()
