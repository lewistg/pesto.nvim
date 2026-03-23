#ifndef _IDS_H_
#define _IDS_H_

#include "digit_num.h"

struct aoc_id_range {
  struct aoc_digit_num *a;
  struct aoc_digit_num *b;
};

int aoc_parse_id_ranges(const char *filename, struct aoc_id_range **id_ranges,
                        size_t *id_ranges_len);

unsigned long aoc_sum_invalid_ids(const struct aoc_id_range id_range);

void aoc_destroy_id_range(struct aoc_id_range *range);

#endif
