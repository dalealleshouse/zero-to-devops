FROM openjdk
COPY . ./usr/src/
WORKDIR /usr/src/
RUN javac -cp ":./lib/*" JConsumer.java
CMD ["java", "-classpath", ":/usr/src/lib/*", "JConsumer"]

