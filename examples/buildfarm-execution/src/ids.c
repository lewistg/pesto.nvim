#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "digit_num.h"
#include "ids.h"

int parse_id_range(char *line, char **save_ptr, struct aoc_id_range *id_range) {
  struct aoc_digit_num *a;
  struct aoc_digit_num *b;

  char *a_str = strtok_r(line, "-", save_ptr);
  if (a_str == NULL) {
    return 1;
  }

  a = aoc_make_digit_num(a_str);
  if (a == NULL) {
    return 1;
  }

  char *b_str = strtok_r(NULL, ",\n", save_ptr);
  if (b_str == NULL) {
    aoc_destroy_digit_num(a);
    return 1;
  }

  b = aoc_make_digit_num(b_str);
  if (b == NULL) {
    aoc_destroy_digit_num(a);
    aoc_destroy_digit_num(b);
    return 1;
  }

  id_range->a = a;
  id_range->b = b;

  return 0;
}

void aoc_destroy_id_range(struct aoc_id_range *range) {
  free(range->a);
  free(range->b);
}

int aoc_parse_id_ranges(const char *filename, struct aoc_id_range **id_ranges,
                        size_t *id_ranges_len) {
  FILE *file = fopen(filename, "r");
  if (file == NULL) {
    return 1;
  }

  char *line;
  size_t len = 0;
  ssize_t n_read = getline(&line, &len, file);
  fclose(file);
  if (n_read == -1 || len == 0) {
    return 1;
  }

  size_t num_ranges = 0;
  for (size_t i = 0; i < len; i++) {
    if (line[i] == ',') {
      num_ranges += 1;
    }
  }
  num_ranges += 1;

  struct aoc_id_range *_id_ranges;
  _id_ranges = (struct aoc_id_range *)malloc(sizeof(*_id_ranges) * num_ranges);

  char *save_ptr;
  for (size_t i = 0; i < num_ranges; i++) {
    parse_id_range(i > 0 ? NULL : line, &save_ptr, _id_ranges + i);
  }

  *id_ranges = _id_ranges;
  *id_ranges_len = num_ranges;

  free(line);

  return 0;
}

static unsigned long ul_pow(unsigned long base, unsigned int pow) {
  long long ret = 1;
  for (int i = 0; i < pow; i++) {
    ret *= base;
  }
  return ret;
}

static long long llmax(long long a, long long b) { return a > b ? a : b; }

static unsigned long sum_remaining_invalid_ids(struct aoc_digit_num *x,
                                               size_t num_fixed_digits) {
  if (x->len % 2 == 1 || x->len == 0) {
    return 0;
  }
  unsigned long num_invalid = 1;
  for (size_t i = num_fixed_digits + 1; i <= x->len / 2; i++) {
    if (i == 0) {
      // No leading zeros. Possible digit values 1-9
      num_invalid *= 9;
    } else {
      // Possible digit values 0-9
      num_invalid *= 10;
    }
  }

  unsigned long sum = 0;
  for (size_t i = 0; i < num_fixed_digits; i++) {
    sum += ul_pow(10, x->len - 1 - i) * x->digits[i] * num_invalid;
    sum +=
        ul_pow(10, llmax((x->len - 1) / 2 - i, 0)) * x->digits[i] * num_invalid;
  }

  for (size_t i = num_fixed_digits + 1; i < x->len / 2; i++) {
    unsigned long num_invalid_per_digit_value = num_invalid / (i == 0 ? 9 : 10);
    // Note: the sum of numbers from 0 to 9 is 45
    sum += ul_pow(10, x->len - 1 - i) * 45 * num_invalid_per_digit_value;
    sum += ul_pow(10, llmax((x->len - 1) / 2 - i, 0)) * 45 *
           num_invalid_per_digit_value;
  }

  return sum;
}

unsigned long
aoc_sum_invalid_ids_recursive(struct aoc_digit_num *x, size_t num_fixed_digits,
                              const struct aoc_id_range id_range) {
  if (x->len % 2 == 1 || x->len == 0) {
    // IDs with odd number of digits can't be invalid since the upper and lower
    // digits cannot repeat.
    return 0;
  }

  if (x->len < id_range.a->len || x->len > id_range.b->len) {
    // We assume x has no leading zeros, so we can tell if x is less than
    // the lower bound or a greater than the upper bound based on its length.
    return 0;
  }

  bool x_equals_a_so_far = true;
  if (x->len == id_range.a->len) {
    for (size_t i = 0; i < num_fixed_digits; i++) {
      if (x->digits[i] < id_range.a->digits[i]) {
        // x is less than our lower bound
        return 0;
      } else if (x->digits[i] > id_range.a->digits[i]) {
        x_equals_a_so_far = false;
        break;
      }
    }
  }

  bool x_equals_b_so_far = true;
  if (x->len == id_range.b->len) {
    for (size_t i = 0; i < num_fixed_digits; i++) {
      if (x->digits[i] > id_range.b->digits[i]) {
        // x is greater than our upper bound
        return 0;
      } else if (x->digits[i] < id_range.b->digits[i]) {
        x_equals_b_so_far = false;
        break;
      }
    }
  }

  if (x->len / 2 == num_fixed_digits) {
    // All digits are fixed. Up this point we haven't been able to
    // definitively confirm the number is in the range [a, b]. This is because
    // if an upper digit is incremented, then there's no restriction on any of
    // the lower digits. So we have to do one last check.
    if (aoc_compare_digit_nums(x, id_range.a) < 0) {
      return 0;
    } else if (aoc_compare_digit_nums(x, id_range.b) > 0) {
      return 0;
    }
    return aoc_digit_num_to_unsigned_long(x);
  }

  if (!x_equals_a_so_far && !x_equals_b_so_far) {
    // x is known to be between a and b (and not equal to either). In other
    // words x is in (a, b) In this case we don't need to recurse further. No
    // matter what we choose for the remaining less significant digits, it
    // can't change the fact that x is in (a, b). In this case there is no
    // constraint on the remaining digits, so we are able to calculate the sum
    // without needing to enumerat them all.
    sum_remaining_invalid_ids(x, num_fixed_digits);
  }

  unsigned long num_invalid = 0;
  size_t next_num_fixed_digits = num_fixed_digits + 1;
  size_t min_digit_value = num_fixed_digits == 0 ? 1 : 0;
  for (unsigned char d = min_digit_value; d <= 9; d++) {
    x->digits[next_num_fixed_digits - 1] = d;
    x->digits[x->len / 2 + next_num_fixed_digits - 1] = d;

    num_invalid +=
        aoc_sum_invalid_ids_recursive(x, next_num_fixed_digits, id_range);
  }

  return num_invalid;
}

unsigned long aoc_sum_invalid_ids(const struct aoc_id_range id_range) {
  unsigned long sum = 0;
  for (size_t i = id_range.a->len; i <= id_range.b->len; i++) {
    struct aoc_digit_num *x = aoc_make_digit_from_ten_pow(i - 1);
    if (x == NULL) {
      return 0;
    }
    sum += aoc_sum_invalid_ids_recursive(x, 0, id_range);
    free(x);
  }
  return sum;
}
