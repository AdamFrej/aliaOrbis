package cc.frej.aliaOrbisPOF.websocket;

import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class GameSocketHandler extends TextWebSocketHandler {

    @Override
    public void afterConnectionEstablished(WebSocketSession session)
        throws Exception {
        System.out.println("Client connected: " + session.getId());
    }

    @Override
    protected void handleTextMessage(
        WebSocketSession session,
        TextMessage message
    ) throws Exception {
        System.out.println("Received message: " + message.getPayload());

        // Echo the message back to the client
        session.sendMessage(
            new TextMessage("Server received: " + message.getPayload())
        );
    }
}
