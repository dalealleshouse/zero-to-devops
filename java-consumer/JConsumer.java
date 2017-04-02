import com.rabbitmq.client.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.util.concurrent.TimeoutException;

public class JConsumer extends DefaultConsumer
{
    public static void main(String[] args) throws IOException, TimeoutException, InterruptedException
    {
        final String host = "queue";
        final String queue = "main_queue";
        boolean error = true;
        while (error)
        {
            Thread.sleep(1000);
            try
            {
                ConnectionFactory factory = new ConnectionFactory();
                factory.setHost(host);
                Connection connection = factory.newConnection();
                Channel channel = connection.createChannel();
                channel.basicQos(1); //accept only one task at a time

                JConsumer c = new JConsumer(channel);
                channel.basicConsume(queue, false, c); //true is auto-ack, which is not what we want. we want to ack manually when task completes. also blocks forever.
                error = false;
            }
            catch (IOException e)
            {
                System.out.println("Error in contacting RabbitMQ. Retrying... " + e.getMessage());
            }
            catch (TimeoutException e)
            {
                System.out.println("Error in contacting RabbitMQ. Retrying... " + e.getMessage());
            }
        }
    }

    JConsumer(Channel ch)
    {
        super(ch);
    }

    @Override
    public void handleDelivery(String consumerTag, Envelope envelope, AMQP.BasicProperties properties, byte[] body) throws IOException
    {
        String message = new String(body, "UTF-8");
        int fib_num;
        try
        {
            fib_num = Integer.parseInt(message);
            System.out.println("\tProcessing fib(" + message + ")...");
            System.out.println("Finished: fib(" + message + "): " + fib(fib_num));
        } catch (NumberFormatException e)
        {
            System.out.println("ERROR: Not an int.");
            return;
        }
        finally
        {
            this.getChannel().basicAck(envelope.getDeliveryTag(), false);
        }
    }

    int fib(int cur)
    {
        if(cur < 2)
            return 1;

        return fib(cur -1) + fib(cur -2);
    }
}
