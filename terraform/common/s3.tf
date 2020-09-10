data aws_caller_identity current {}

resource aws_s3_bucket db_backups {
  bucket = "${data.aws_caller_identity.current.account_id}-tv-db-backups"
}