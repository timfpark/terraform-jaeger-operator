/*
resource "kubernetes_namespace" "jaeger_namespace" {
  metadata {
    name = "${var.namespace}"
  }
}
*/

resource "null_resource" "jaeger_service_account" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/service_account.yaml"
  }

  // depends_on = ["kubernetes_namespace.jaeger_namespace"]
}

resource "null_resource" "jaeger_role" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/role.yaml"
  }

  depends_on = ["null_resource.jaeger_service_account"]
}

resource "null_resource" "jaeger_role_binding" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/role_binding.yaml"
  }

  depends_on = ["null_resource.jaeger_role"]
}

resource "null_resource" "jaeger_operator" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/operator.yaml"
  }

  depends_on = ["null_resource.jaeger_role_binding"]
}

resource "null_resource" "jaeger_crd" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/io_v1alpha1_jaeger_crd.yaml"
  }

  depends_on = ["null_resource.jaeger_operator"]
}

resource "null_resource" "jaeger_service" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/service.yaml"
  }

  depends_on = ["null_resource.jaeger_crd"]
}

data "template_file" "jaeger" {
  template = "${file("${path.module}/deployment.yaml.tmpl")}"

  vars {
    name                          = "${var.name}"
    namespace                     = "${var.namespace}"
    elasticsearch_client_endpoint = "${var.elasticsearch_client_endpoint}"
  }
}

resource "null_resource" "generate_jaeger_operator_yaml" {
  provisioner "local-exec" {
    command = "echo '${data.template_file.jaeger.rendered}' > ${path.module}/deployment.yaml"
  }

  depends_on = ["data.template_file.jaeger"]
}

resource "null_resource" "jaeger_deployment" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/deployment.yaml"
  }

  depends_on = ["null_resource.generate_jaeger_operator_yaml", "null_resource.jaeger_crd"]
}
