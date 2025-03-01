/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "google_compute_region_network_endpoint_group" "psc_neg" {
  project               = var.project_id
  name                  = "psc-neg-${var.neg_single_region}"
  region                = var.neg_single_region
  network_endpoint_type = "PRIVATE_SERVICE_CONNECT"
  psc_target_service    = var.psc_service_attachments[var.neg_single_region]
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_backend_service" "psc_backend" {
  project               = var.project_id
  name                  = "psc-neg-backend"
  port_name             = "https"
  protocol              = "HTTPS"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  backend {
    group = google_compute_region_network_endpoint_group.psc_neg.id
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_url_map" "url_map" {
  project         = var.project_id
  name            = var.name
  default_service = google_compute_backend_service.psc_backend.id
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project          = var.project_id
  name             = "${var.name}-target-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [var.ssl_certificate]
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  project               = var.project_id
  name                  = "${var.name}-forwarding-rule"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = var.external_ip != null ? var.external_ip : null
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}

