resource "aws_sns_topic" "this" {
  name = "sns_topic"
}

resource "aws_sns_topic_subscription" "this" {
  protocol = "email"
  topic_arn = aws_sns_topic.this.arn
  endpoint = var.email_address
}