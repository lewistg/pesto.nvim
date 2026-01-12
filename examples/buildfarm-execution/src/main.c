#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ids.h"

/**
 * A solution to day 2 part 1 of Advent of Code 2025 [1].
 *
 * [1]: https://adventofcode.com/2025/day/2
 */

int main(int argc, char **argv) {
  if (argc < 2) {
    fprintf(stderr, "missing input file\n");
    exit(1);
  }

  struct aoc_id_range *id_ranges = NULL;
  size_t id_ranges_len = 0;
  aoc_parse_id_ranges(argv[argc - 1], &id_ranges, &id_ranges_len);

  unsigned long sum = 0;

  for (size_t i = 0; i < id_ranges_len; i++) {
    sum += aoc_sum_invalid_ids(id_ranges[i]);
    aoc_destroy_id_range(id_ranges + i);
  }

  printf("invalid ID sum: %lu\n", sum);

  free(id_ranges);

  return 0;
}
