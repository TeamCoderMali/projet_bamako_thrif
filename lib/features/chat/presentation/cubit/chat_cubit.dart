// ─── Bamako Thrift — Chat Cubit & State ────────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';

// ── States ─────────────────────────────────────────────────────────────────
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatsLoaded extends ChatState {
  final List<ChatEntity> chats;
  const ChatsLoaded(this.chats);
  @override
  List<Object?> get props => [chats];
}

class MessagesLoaded extends ChatState {
  final List<MessageEntity> messages;
  final ChatEntity chat;
  const MessagesLoaded({required this.messages, required this.chat});
  @override
  List<Object?> get props => [messages, chat];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────
class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _repository;

  ChatCubit({required ChatRepository repository})
      : _repository = repository,
        super(const ChatInitial());

  Future<void> loadChats() async {
    emit(const ChatLoading());
    try {
      final chats = await _repository.getMyChats();
      emit(ChatsLoaded(chats));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> openChat(String chatId) async {
    emit(const ChatLoading());
    try {
      final chat = await _repository.getChatById(chatId);
      // Les messages seront chargés via le stream dans la page
      emit(MessagesLoaded(messages: const [], chat: chat));
      await _repository.markAsRead(chatId);
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Future<void> sendMessage({
    required String chatId,
    required String content,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) async {
    try {
      await _repository.sendMessage(
        chatId: chatId,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
      );
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  Stream<List<MessageEntity>> watchMessages(String chatId) =>
      _repository.watchMessages(chatId);
}
