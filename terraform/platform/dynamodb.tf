# The votes table. Lives in this destroyable stack, so votes reset on each teardown
# (fine for a demo; move it to an always-on stack if they should survive).

resource "aws_dynamodb_table" "votes" {
  name         = "${var.project}-votes"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }
}

#   The api reads the table name from its TABLE_NAME env var, so the Phase 6
#   manifest sets TABLE_NAME=eks-gitops-demo-votes (not the "votes" default in api.py).


