package X;

use v5.40;
use utf8::all;

use version 0.77; our $VERSION = version->declare("v0.1.1");

use X::File;
use X::Selenium;
use X::Sleep;
use X::Log;
use X::HTML;
use X::DB;
use X::Time;
use Exporter 'import';

our @EXPORT = qw(
  ff_file_put_contents
  ff_file_get_contents
  ff_find_file_abs
  ff_find_file_rel
  ff_join_path
  ff_make_dir
  ff_dirname
  ff_basename
  ff_basename_without_ext
  ff_get_extention
  ff_file_to_abs
  ff_is_dir_exists

  ss_sleep
  ss_sleep_random

  init_logger
  log_info
  log_warn
  log_error
  log_debug
  log_success

  hp_create_document
  hp_find_element
  hp_find_elements
  hp_get_text
  hp_get_attr
  hp_get_outer_html
  hp_get_inner_html
  hp_remove_doc
);

1;
