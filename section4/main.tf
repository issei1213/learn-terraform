provider "aws" {
    profile = "terraform"
    region = "ap-northeast-1"
}

resource "aws_instance" "hello-world" {
    ami = ""
    instance_type = "t2.micro"
}

