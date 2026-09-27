export type ChatMessagePayload = {
  id: string;
  roomId: string;
  occurrenceId: string;
  sender: {
    id: string;
    name: string | null;
    avatarUrl: string | null;
  };
  body: string;
  createdAt: string;
};

export type ChatWsClientMessage =
  | { type: 'join'; occurrenceId: string }
  | { type: 'message'; body: string };

export type ChatWsServerMessage =
  | { type: 'joined'; occurrenceId: string; roomId: string }
  | { type: 'message'; message: ChatMessagePayload }
  | { type: 'error'; message: string };
