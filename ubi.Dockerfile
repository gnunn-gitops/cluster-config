FROM registry.redhat.io/ubi8/ubi
ENTRYPOINT ["sh","-c", "echo Hello World!;sleep 3600"]
