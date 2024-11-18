resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  name            = var.rule_name
  event_bus_name  = aws_cloudwatch_event_bus.event_bus.name
  event_pattern   = var.event_pattern
  force_destroy = true
}

resource "aws_cloudwatch_event_target" "eventbridge_rule_target" {
  rule           = aws_cloudwatch_event_rule.eventbridge_rule.name
  arn            = var.target_arn
  role_arn       = var.rule_role_arn
  event_bus_name = var.event_bus_name

  depends_on = [aws_cloudwatch_event_rule.eventbridge_rule]
}

resource "aws_cloudwatch_event_bus" "event_bus" {
  name = var.event_bus_name
  
}

resource "aws_cloudwatch_event_bus_policy" "event_bus_policy" {
  policy = var.event_bus_policy
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  
  
}
