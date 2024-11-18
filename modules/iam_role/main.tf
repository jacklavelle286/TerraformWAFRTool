resource "aws_iam_role" "role" {
  name = var.role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "${var.assume_role_service}.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "policy" {
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "${var.policy_choice}",
        "Action": "${var.policy_service}:${var.api_call}",
        "Resource": "${var.resource}"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attachment" {
  policy_arn = aws_iam_policy.policy.arn
  role = aws_iam_role.role.id
}