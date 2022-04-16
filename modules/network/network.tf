resource "aws_nat_gateway" "main" {
  # add a nat gateway for each 
  count         = length(var.subnets_private)
  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id     = element(var.subnets_public, count.index)
  depends_on    = [var.igw_id]
  tags          = var.tags
}

resource "aws_eip" "nat" {
  # assign elastic IP to each nat gateway
  count = length(var.subnets_private)
  vpc   = true
}


# PRIVATE ROUTE TABLE ----------------
resource "aws_route_table" "private" {
  # create route table in vpc for each subnet
  count  = length(var.subnets_private)
  vpc_id = var.vpc_id
  tags   = var.tags
}

resource "aws_route" "private" {
  # create route for each subnet, attach nat gateway id
  count                  = length(compact(var.subnets_private))
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.main.*.id, count.index)
}

# resource "aws_route_table_association" "private" {
#   # associate route to subnet
#   count          = length(var.subnets_private)
#   subnet_id      = element(var.subnets_private, count.index)
#   route_table_id = element(aws_route_table.private.*.id, count.index)
# }
