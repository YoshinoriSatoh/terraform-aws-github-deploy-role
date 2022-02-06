# デフォルトリージョン
provider "aws" {
  region  = var.region
  profile = var.profile 

  default_tags {
    tags = {
      TfName = var.tf.name
      TfEnv  = var.tf.env
    }
  }
}
