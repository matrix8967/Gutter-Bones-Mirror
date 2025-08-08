# Minimal Ansible runner for consistent local/CI execution
FROM python:3.12-slim

ENV PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    ANSIBLE_FORCE_COLOR=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends gcc sshpass git openssh-client \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --disable-pip-version-check \
    ansible==9.7.0 \
    ansible-core==2.16.8 \
    ansible-lint==24.6.0 \
    yamllint==1.35.1 \
    pre-commit==3.7.1

# Install Galaxy collections pinned by requirements.yml
WORKDIR /workspace
COPY requirements.yml /workspace/
RUN ansible-galaxy collection install -r requirements.yml

# Default command prints versions
CMD ["bash", "-lc", "ansible --version && ansible-lint --version && yamllint --version"]
