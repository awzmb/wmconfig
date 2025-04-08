FROM docker.io/hashicorp/terraform:1.7.5 AS terraform
FROM docker.io/cytopia/terraform-docs:0.16.0 AS terraform-docs

FROM python:3.13-slim AS build

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --upgrade pip
RUN pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org pre-commit

RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=terraform /bin/terraform /usr/local/bin/terraform
COPY --from=terraform-docs /usr/local/bin/terraform-docs /usr/local/bin/terraform-docs

#FROM gcr.io/distroless/python3-debian12:nonroot

#COPY --from=build /opt/venv /opt/venv

#ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app

ENTRYPOINT ["pre-commit"]
