FROM python:3.10-slim
RUN apt-get update && apt-get install -y git curl wget ruby golang nmap dnsutils
WORKDIR /app
COPY . .
RUN chmod +x trx.sh engine/*.sh engine/*.py
CMD ["./trx.sh"]
