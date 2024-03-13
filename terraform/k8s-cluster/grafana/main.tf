data "grafana_data_source" "prometheus" {
  name = "Prometheus"
}

resource "grafana_contact_point" "base_alert" {
  name = "Base Alert via Microsoft Team"
  teams {
    url                     = var.webhook_team
    title                   = "Systemtest Metric Error Alert !!!"
    disable_resolve_message = true
    message                 = <<EOT
{{ range .Alerts.Firing }}
Alert summaries:
{{ template "Alert Instance Template" . }}
{{ end }}
EOT
  }
}

resource "grafana_contact_point" "log_alert" {
  name = "Log Alert via Microsoft Team"
  teams {
    disable_resolve_message = true
    url                     = var.webhook_team
    title                   = "Systemtest Log Error Alert !!!"
    message                 = <<EOT
{{ template "ErrorLogMessage" . }}
    EOT
  }
}

resource "grafana_message_template" "base_alert" {
  name     = "Prometheus Alert Template"
  template = <<EOT
{{ define "Alert Instance Template" }}
{{ range .Annotations.SortedPairs }} 
  - {{ .Name }} = {{ .Value }} 
{{ end }}
{{ end}}
EOT
}


resource "grafana_notification_policy" "notification_policy" {
  group_by        = ["..."]
  contact_point   = grafana_contact_point.base_alert.name
  group_wait      = "45s"
  group_interval  = "4m"
  repeat_interval = "1h"
  policy {
    matcher {
      label = "datasource"
      match = "="
      value = "Prometheus"
    }
    contact_point   = grafana_contact_point.base_alert.name
    group_by        = ["alertname"]
    continue        = true
    group_wait      = "45s"
    group_interval  = "4m"
    repeat_interval = "1h"
  }
}


resource "grafana_folder" "prometheus_alert" {
  title = "Prometheus Alert Provisioning by Terraform"
}



resource "grafana_rule_group" "prometheus_alert" {
  name             = "Prometheus Alert Rule Group"
  folder_uid       = grafana_folder.prometheus_alert.uid
  interval_seconds = 60
  //org_id           = 1
  rule {
    name           = "Pod High CPU Resource"
    for            = "2m"
    condition      = "B"
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    is_paused      = false
    annotations = {
      "Pod"     = "{{ $labels.pod }}"
      "Summary" = "Pod have high resource than permit for 2 minutes - (CPU > 85%)"
    }
    labels = {
      "env"        = "${var.env}"
      "datasource" = "Prometheus"
    }
    data {
      ref_id     = "A"
      query_type = ""
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = data.grafana_data_source.prometheus.uid
      model = jsonencode({
        editorMode = "code"
        datasource = {
          type = "prometheus",
          uid  = "${data.grafana_data_source.prometheus.uid}"
        }
        expr          = "(sum(node_namespace_pod_container:container_cpu_usage_seconds_total:sum_irate{cluster=~\".*\", namespace=~\".*\", pod=~\".*\"}) by (container,pod,namespace) / sum(cluster:namespace:pod_cpu:active:kube_pod_container_resource_limits{cluster=~\".*\", namespace=~\".*\", pod=~\".*\"}) by (container,pod,namespace)) \u003e= 0.85"
        intervalMs    = 1000
        legendFormat  = "__auto"
        maxDataPoints = 43200
        range         = true
        hide          = false
        refId         = "A"
      })
    }

    data {
      ref_id     = "B"
      query_type = ""
      relative_time_range {
        from = 0
        to   = 0
      }
      datasource_uid = "-100" # Expression query type
      model          = <<EOT
      {
        "conditions": [
          {
            "evaluator": {
              "params": [
                3
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A"
              ]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }
      EOT
    }
  }

  rule {
    name           = "target Status Check"
    for            = "1m"
    condition      = "C"
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    is_paused      = false
    annotations = {
      "Pod"     = "{{ $labels.pod }}"
      "Summary" = "containers target Status Check {status != UP }"
    }
    labels = {
      "env"        = "${var.env}"
      "datasource" = "Prometheus"
    }
    data {
      ref_id = "A"

      relative_time_range {
        from = 600
        to   = 0
      }

      datasource_uid = "prometheus"
      model          = "{\"disableTextWrap\":false,\"editorMode\":\"builder\",\"expr\":\"probe_http_status_code\",\"fullMetaSearch\":false,\"includeNullMetadata\":true,\"instant\":true,\"intervalMs\":1000,\"legendFormat\":\"__auto\",\"maxDataPoints\":100,\"range\":false,\"refId\":\"A\",\"useBackend\":false}"
    }
    data {
      ref_id = "B"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[0,0],\"type\":\"gt\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[]},\"reducer\":{\"params\":[],\"type\":\"avg\"},\"type\":\"query\"}],\"datasource\":{\"name\":\"Expression\",\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"A\",\"intervalMs\":1000,\"maxDataPoints\":100,\"reducer\":\"last\",\"refId\":\"B\",\"type\":\"reduce\"}"
    }
    data {
      ref_id = "C"

      relative_time_range {
        from = 0
        to   = 0
      }

      datasource_uid = "__expr__"
      model          = "{\"conditions\":[{\"evaluator\":{\"params\":[200,201],\"type\":\"outside_range\"},\"operator\":{\"type\":\"and\"},\"query\":{\"params\":[]},\"reducer\":{\"params\":[],\"type\":\"avg\"},\"type\":\"query\"}],\"datasource\":{\"name\":\"Expression\",\"type\":\"__expr__\",\"uid\":\"__expr__\"},\"expression\":\"B\",\"intervalMs\":1000,\"maxDataPoints\":100,\"refId\":\"C\",\"type\":\"threshold\"}"
    }
  }



// 
  rule {
    name      = "Pod Crash Loopping"
    for       = "5m"
    condition = "B"
    annotations = {
      "Pod"     = "{{ $labels.pod }}"
      "Summary" = "Pod is in waiting state (reason: \"CrashLoopBackOff\")"
    }
    labels = {
      "env"        = "${var.env}"
      "datasource" = "Prometheus"
    }
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      query_type = ""
      model = jsonencode({
        editorMode = "code"
        datasource = {
          type = "prometheus",
          uid  = "${data.grafana_data_source.prometheus.uid}"
        }
        expr          = "max_over_time(kube_pod_container_status_waiting_reason{job=\"kube-state-metrics\",namespace=~\".*\",reason=\"CrashLoopBackOff\"}[5m]) \u003e= 1"
        intervalMs    = 1000
        legendFormat  = "__auto"
        maxDataPoints = 43200
        range         = true
        hide          = false
        refId         = "A"
      })
    }
    data {
      ref_id         = "B"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = <<EOT
      {
        "conditions": [
          {
            "evaluator": {
              "params": [
                3
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A"
              ]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }   
      EOT
    }
  }

rule {
    name      = "Pod Not Ready"
    for       = "5m"
    condition = "B"
    annotations = {
      "Pod"     = "{{ $labels.pod }}"
      "Summary" = "Pod has been in a non-ready state for more than 5 minutes"
    }
    labels = {
      "env"        = "${var.env}"
      "datasource" = "Prometheus"
    }
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 600
        to   = 0
      }
      query_type = ""
      model = jsonencode({
        editorMode = "code"
        datasource = {
          type = "prometheus",
          uid  = "${data.grafana_data_source.prometheus.uid}"
        }
        expr          =  " sum by (namespace, pod, cluster) (max by(namespace, pod, cluster) (kube_pod_status_phase{job=\"kube-state-metrics\", namespace=~\"{{ $targetNamespace }}\", phase=~\"Pending|Unknown|Failed\"}) * on(namespace, pod, cluster) group_left(owner_kind) topk by(namespace, pod, cluster) (1, max by(namespace, pod, owner_kind, cluster) (kube_pod_owner{owner_kind!=\"Job\"}))) > 0"
        intervalMs    = 1000
        legendFormat  = "__auto"
        maxDataPoints = 43200
        range         = true
        hide          = false
        refId         = "A"
      })
    }
    data {
      ref_id         = "B"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = <<EOT
      {
        "conditions": [
          {
            "evaluator": {
              "params": [
                3
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A"
              ]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }   
      EOT
    }
  }

rule {
    name      = "Deployment Replicas Mismatch"
    for       = "15m"
    condition = "B"
    annotations = {
      "Pod"     = "{{ $labels.pod }}"
      "Summary" = "Deployment has not matched the expected number of replicas for more than 15 minutes"
    }
    labels = {
      "env"        = "${var.env}"
      "datasource" = "Prometheus"
    }
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 1800
        to   = 0
      }
      query_type = ""
      model = jsonencode({
        editorMode = "code"
        datasource = {
          type = "prometheus",
          uid  = "${data.grafana_data_source.prometheus.uid}"
        }
        expr          =  "(kube_deployment_spec_replicas{job=\"kube-state-metrics\", namespace=~\"{{ $targetNamespace }}\"} > kube_deployment_status_replicas_available{job=\"kube-state-metrics\", namespace=~\"{{ $targetNamespace }}\"}) and (changes(kube_deployment_status_replicas_updated{job=\"kube-state-metrics\", namespace=~\"{{ $targetNamespace }}\"}[10m]) == 0)"
        intervalMs    = 1000
        legendFormat  = "__auto"
        maxDataPoints = 43200
        range         = true
        hide          = false
        refId         = "A"
      })
    }
    data {
      ref_id         = "B"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = <<EOT
      {
        "conditions": [
          {
            "evaluator": {
              "params": [
                3
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A"
              ]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }   
      EOT
    }
  }

rule {
    name      = "Job Not Completed"
    for       = "1h"
    condition = "B"
    annotations = {
      "Pod"     = "{{ $labels.job_name }}"
      "Summary" = "Job did not complete in time"
    }
    labels = {
      "env"        = "${var.env}"
      "datasource" = "Prometheus"
    }
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 3600
        to   = 0
      }
      query_type = ""
      model = jsonencode({
        editorMode = "code"
        datasource = {
          type = "prometheus",
          uid  = "${data.grafana_data_source.prometheus.uid}"
        }
        expr          =  "time() - max by (namespace, job_name, cluster) (kube_job_status_start_time{job=\"kube-state-metrics\",namespace=~\".*\"} and kube_job_status_active{job=\"kube-state-metrics\",namespace=~\".*\"} > 0) > 43200"
        intervalMs    = 1000
        legendFormat  = "__auto"
        maxDataPoints = 43200
        range         = true
        hide          = false
        refId         = "A"
      })
    }
    data {
      ref_id         = "B"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = <<EOT
      {
        "conditions": [
          {
            "evaluator": {
              "params": [
                3
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A"
              ]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }   
      EOT
    }
  }

rule {
    name      = "Job Failed"
    for       = "1h"
    condition = "B"
    annotations = {
      "Pod"     = "{{ $labels.job_name }}"
      "Summary" = "Job failed to complete"
    }
    labels = {
      "env"        = "${var.env}"
      "datasource" = "Prometheus"
    }
    no_data_state  = "OK"
    exec_err_state = "Alerting"
    data {
      ref_id         = "A"
      datasource_uid = data.grafana_data_source.prometheus.uid
      relative_time_range {
        from = 3600
        to   = 0
      }
      query_type = ""
      model = jsonencode({
        editorMode = "code"
        datasource = {
          type = "prometheus",
          uid  = "${data.grafana_data_source.prometheus.uid}"
        }
        expr          =  "kube_job_failed{job=\"kube-state-metrics\",namespace=~\".*\"} > 0"
        intervalMs    = 1000
        legendFormat  = "__auto"
        maxDataPoints = 43200
        range         = true
        hide          = false
        refId         = "A"
      })
    }
    data {
      ref_id         = "B"
      datasource_uid = "-100"
      relative_time_range {
        from = 0
        to   = 0
      }
      model = <<EOT
      {
        "conditions": [
          {
            "evaluator": {
              "params": [
                3
              ],
              "type": "gt"
            },
            "operator": {
              "type": "and"
            },
            "query": {
              "params": [
                "A"
              ]
            },
            "reducer": {
              "params": [],
              "type": "last"
            },
            "type": "query"
          }
        ],
        "datasource": {
          "type": "__expr__",
          "uid": "-100"
        },
        "expression": "A",
        "hide": false,
        "intervalMs": 1000,
        "maxDataPoints": 43200,
        "reducer": "last",
        "refId": "B",
        "type": "reduce"
      }   
      EOT
    }
  }
}

