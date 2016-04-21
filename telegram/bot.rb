class Bot

  Token = Config::Telegram.env.token

  def initialize
    LOG.info 'Bot started'
    @client = Telegram::Bot::Client
  end

  def start
    loop do
      begin
        @client.run(Token) do |bot|
          @bot = bot
          bot.listen do |message|
            process message
          end
        end
      rescue Exception => e
        LOG.error e
      end
    end
  end

  private

  def process msg
    LOG.debug msg.to_yaml
    case msg
      when Telegram::Bot::Types::InlineQuery
        process_inline msg
      when Telegram::Bot::Types::Message
        process_message msg
      when Telegram::Bot::Types::CallbackQuery
        process_cb msg
    end
  end

  def process_inline query
    location = query.location
    if location.nil?
      url_button = Telegram::Bot::Types::InlineKeyboardButton.new text: 'Попробовать онлайн',
                                                                  url: 'http://rasp.orgp.spb.ru/'
      message = Telegram::Bot::Types::InputTextMessageContent.new message_text: 'Пожалуйста, разрешите доступ к вашему местоположению',
                                                                  parse_mode: 'Markdown'
      keyboard = Telegram::Bot::Types::InlineKeyboardMarkup.new inline_keyboard: [[url_button]]
      result = Telegram::Bot::Types::InlineQueryResultArticle.new id: rand,
                                                                  title: 'Разрешите местоположение',
                                                                  reply_markup: keyboard,
                                                                  input_message_content: message
    else
      text = RaspApi.get_stops(location)
      message = Telegram::Bot::Types::InputTextMessageContent.new message_text: text
      result = Telegram::Bot::Types::InlineQueryResultArticle.new id: rand,
                                                                  url: text,
                                                                  title: 'Ближайшие остановки',
                                                                  input_message_content: message
    end
    @bot.api.answer_inline_query inline_query_id: query.id,
                                 results: [result]
  end

  def process_message message
    case message.text
      when '/start'
        @bot.api.send_message chat_id: message.chat.id, text: "Hello, #{message.from.first_name}"
      when '/stop'
        @bot.api.send_message chat_id: message.chat.id, text: "Bye, #{message.from.first_name}"
      else
        if message.location.nil?
          unless system_message? message
            button = Telegram::Bot::Types::KeyboardButton.new text: 'Поделиться местоположением',
                                                              request_location: true
            markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new keyboard:[[button]]
            @bot.api.send_message chat_id: message.chat.id,
                                  reply_markup: markup,
                                  text: 'Отправьте мне местоположение'
           end
        else
          reply_with_stops message.chat.id, message.location
        end
    end

  end

  def process_cb msg

  end

  def system_message? msg
    puts msg.text =~ /http:\/\/rasp.orgp.spb.ru\/*/
   !(msg.text =~ /http:\/\/rasp.orgp.spb.ru\/*/).nil?
  end

  def reply_with_stops chat_id, loc
    @bot.api.send_message chat_id: chat_id,
                          text: "[#{RaspApi.get_stops(loc)}]",
                          parse_mode: 'Markdown'
  end

  def default_answer
    "Ваше местоположение недоступно. Пожалуйста, отправьте ваш Location, или посетитие [http://rasp.orgp.spb.ru/](сайт)"
  end
end