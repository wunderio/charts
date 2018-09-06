#!/bin/bash

helm package drupal --destination docs
helm repo index docs --url https://wunderio.github.io/charts/
