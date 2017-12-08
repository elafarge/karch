/*
 * IAM policies for kops are defined here, according to the "kops-policies" variable
 */

# Kops
resource "aws_iam_group" "kops" {
  name = "kops-test"
  path = "/"
}

resource "aws_iam_group_policy_attachment" "kops" {
  count      = "${length(var.kops-policies)}"
  group      = "${aws_iam_group.kops.name}"
  policy_arn = "arn:aws:iam::aws:policy/${element(var.kops-policies, count.index)}"
}

resource "aws_iam_group_membership" "kops" {
  name  = "kops-membership"
  group = "${aws_iam_group.kops.name}"
  users = ["${aws_iam_user.kops.name}"]
}

resource "aws_iam_user" "kops" {
  name = "kops-test"
  path = "/"
}
