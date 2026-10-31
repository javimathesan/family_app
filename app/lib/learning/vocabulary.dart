/// Idiomas que se pueden aprender (la base es el español).
enum Lang {
  en('Inglés', '🇺🇸', 'en-US'),
  pt('Portugués', '🇧🇷', 'pt-BR'),
  ko('Coreano', '🇰🇷', 'ko-KR');

  const Lang(this.label, this.flag, this.ttsLocale);
  final String label;
  final String flag;

  /// Idioma para la voz del teléfono.
  final String ttsLocale;

  static Lang? byCode(String code) => values.asNameMap()[code];
}

/// Una palabra con su dibujo y sus traducciones.
class Word {
  const Word(this.emoji, this.es, this.en, this.pt, this.ko, this.koRoman);
  final String emoji;
  final String es;
  final String en;
  final String pt;
  final String ko;

  /// Cómo se lee el coreano con nuestras letras.
  final String koRoman;

  String inLang(Lang lang) => switch (lang) {
        Lang.en => en,
        Lang.pt => pt,
        Lang.ko => ko,
      };

  /// Ayuda para leer (solo en coreano).
  String? hint(Lang lang) => lang == Lang.ko ? koRoman : null;
}

/// Nivel de dificultad de los temas.
enum WordLevel {
  basico('Básico', 'Las primeras palabras'),
  medio('Medio', 'Más temas y palabras'),
  avanzado('Avanzado', 'Frases, días y emociones');

  const WordLevel(this.label, this.description);
  final String label;
  final String description;
}

class Topic {
  const Topic(this.id, this.label, this.emoji, this.words, {this.level = WordLevel.basico, this.pack = false});

  /// Viene de un paquete descargado (no está dentro de la app).
  final bool pack;
  final String id;
  final String label;
  final String emoji;
  final List<Word> words;
  final WordLevel level;
}

List<Topic> topicsOf(WordLevel level) => [for (final t in topics) if (t.level == level) t];

/// Temas que llegan en paquetes desde el servidor (se suman sin actualizar la app).
List<Topic> extraTopics = [];

/// Todos los temas: los de la app y los de los paquetes.
List<Topic> get topics => [...builtInTopics, for (final t in extraTopics) if (!builtInTopics.any((b) => b.id == t.id)) t];

/// Vocabulario básico por temas.
const builtInTopics = [
  Topic('colores', 'Colores', '🎨', [
    Word('🔴', 'rojo', 'red', 'vermelho', '빨간색', 'ppalgansaek'),
    Word('🔵', 'azul', 'blue', 'azul', '파란색', 'paransaek'),
    Word('🟢', 'verde', 'green', 'verde', '초록색', 'choroksaek'),
    Word('🟡', 'amarillo', 'yellow', 'amarelo', '노란색', 'noransaek'),
    Word('⚫', 'negro', 'black', 'preto', '검은색', 'geomeunsaek'),
    Word('⚪', 'blanco', 'white', 'branco', '흰색', 'huinsaek'),
    Word('🟠', 'naranja', 'orange', 'laranja', '주황색', 'juhwangsaek'),
    Word('🟣', 'violeta', 'purple', 'roxo', '보라색', 'borasaek'),
  ]),
  Topic('numeros', 'Números', '🔢', [
    Word('1️⃣', 'uno', 'one', 'um', '하나', 'hana'),
    Word('2️⃣', 'dos', 'two', 'dois', '둘', 'dul'),
    Word('3️⃣', 'tres', 'three', 'três', '셋', 'set'),
    Word('4️⃣', 'cuatro', 'four', 'quatro', '넷', 'net'),
    Word('5️⃣', 'cinco', 'five', 'cinco', '다섯', 'daseot'),
    Word('6️⃣', 'seis', 'six', 'seis', '여섯', 'yeoseot'),
    Word('7️⃣', 'siete', 'seven', 'sete', '일곱', 'ilgop'),
    Word('8️⃣', 'ocho', 'eight', 'oito', '여덟', 'yeodeol'),
    Word('9️⃣', 'nueve', 'nine', 'nove', '아홉', 'ahop'),
    Word('🔟', 'diez', 'ten', 'dez', '열', 'yeol'),
  ]),
  Topic('animales', 'Animales', '🐾', [
    Word('🐶', 'perro', 'dog', 'cachorro', '개', 'gae'),
    Word('🐱', 'gato', 'cat', 'gato', '고양이', 'goyangi'),
    Word('🐮', 'vaca', 'cow', 'vaca', '소', 'so'),
    Word('🐴', 'caballo', 'horse', 'cavalo', '말', 'mal'),
    Word('🐦', 'pájaro', 'bird', 'pássaro', '새', 'sae'),
    Word('🐟', 'pez', 'fish', 'peixe', '물고기', 'mulgogi'),
    Word('🦁', 'león', 'lion', 'leão', '사자', 'saja'),
    Word('🐘', 'elefante', 'elephant', 'elefante', '코끼리', 'kokkiri'),
    Word('🐰', 'conejo', 'rabbit', 'coelho', '토끼', 'tokki'),
    Word('🐵', 'mono', 'monkey', 'macaco', '원숭이', 'wonsungi'),
  ]),
  Topic('comida', 'Comida', '🍎', [
    Word('💧', 'agua', 'water', 'água', '물', 'mul'),
    Word('🍞', 'pan', 'bread', 'pão', '빵', 'ppang'),
    Word('🥛', 'leche', 'milk', 'leite', '우유', 'uyu'),
    Word('🍎', 'manzana', 'apple', 'maçã', '사과', 'sagwa'),
    Word('🍌', 'banana', 'banana', 'banana', '바나나', 'banana'),
    Word('🥚', 'huevo', 'egg', 'ovo', '달걀', 'dalgyal'),
    Word('🍚', 'arroz', 'rice', 'arroz', '밥', 'bap'),
    Word('🧀', 'queso', 'cheese', 'queijo', '치즈', 'chijeu'),
    Word('🍦', 'helado', 'ice cream', 'sorvete', '아이스크림', 'aiseukeurim'),
  ]),
  Topic('familia', 'Familia', '👨‍👩‍👧', [
    Word('👩', 'mamá', 'mom', 'mãe', '엄마', 'eomma'),
    Word('👨', 'papá', 'dad', 'pai', '아빠', 'appa'),
    Word('👦', 'hermano', 'brother', 'irmão', '형제', 'hyeongje'),
    Word('👧', 'hermana', 'sister', 'irmã', '자매', 'jamae'),
    Word('👴', 'abuelo', 'grandpa', 'avô', '할아버지', 'harabeoji'),
    Word('👵', 'abuela', 'grandma', 'avó', '할머니', 'halmeoni'),
    Word('👶', 'bebé', 'baby', 'bebê', '아기', 'agi'),
    Word('👨‍👩‍👧‍👦', 'familia', 'family', 'família', '가족', 'gajok'),
  ]),
  Topic('casa', 'La casa', '🏠', [
    Word('🏠', 'casa', 'house', 'casa', '집', 'jip'),
    Word('🛏️', 'cama', 'bed', 'cama', '침대', 'chimdae'),
    Word('🚪', 'puerta', 'door', 'porta', '문', 'mun'),
    Word('🪟', 'ventana', 'window', 'janela', '창문', 'changmun'),
    Word('🪑', 'silla', 'chair', 'cadeira', '의자', 'uija'),
    Word('🍽️', 'mesa', 'table', 'mesa', '식탁', 'siktak'),
    Word('🚽', 'baño', 'bathroom', 'banheiro', '화장실', 'hwajangsil'),
    Word('🍳', 'cocina', 'kitchen', 'cozinha', '부엌', 'bueok'),
  ]),
  Topic('colegio', 'El colegio', '🏫', [
    Word('🏫', 'escuela', 'school', 'escola', '학교', 'hakgyo'),
    Word('📕', 'libro', 'book', 'livro', '책', 'chaek'),
    Word('✏️', 'lápiz', 'pencil', 'lápis', '연필', 'yeonpil'),
    Word('👩‍🏫', 'maestra', 'teacher', 'professora', '선생님', 'seonsaengnim'),
    Word('🎒', 'mochila', 'backpack', 'mochila', '가방', 'gabang'),
    Word('📓', 'cuaderno', 'notebook', 'caderno', '공책', 'gongchaek'),
    Word('🧑‍🤝‍🧑', 'amigo', 'friend', 'amigo', '친구', 'chingu'),
    Word('✂️', 'tijera', 'scissors', 'tesoura', '가위', 'gawi'),
  ]),
  // ------------------------------------------------------------- nivel medio
  Topic('ropa', 'Ropa', '👕', level: WordLevel.medio, [
    Word('👕', 'remera', 't-shirt', 'camiseta', '티셔츠', 'tisyeocheu'),
    Word('👖', 'pantalón', 'pants', 'calça', '바지', 'baji'),
    Word('👟', 'zapatillas', 'sneakers', 'tênis', '운동화', 'undonghwa'),
    Word('🧢', 'gorra', 'cap', 'boné', '모자', 'moja'),
    Word('🧦', 'medias', 'socks', 'meias', '양말', 'yangmal'),
    Word('🧥', 'campera', 'jacket', 'jaqueta', '재킷', 'jaekit'),
    Word('👗', 'vestido', 'dress', 'vestido', '원피스', 'wonpiseu'),
    Word('🧣', 'bufanda', 'scarf', 'cachecol', '목도리', 'mokdori'),
  ]),
  Topic('cuerpo', 'El cuerpo', '🧍', level: WordLevel.medio, [
    Word('🗣️', 'cabeza', 'head', 'cabeça', '머리', 'meori'),
    Word('👀', 'ojos', 'eyes', 'olhos', '눈', 'nun'),
    Word('👃', 'nariz', 'nose', 'nariz', '코', 'ko'),
    Word('👄', 'boca', 'mouth', 'boca', '입', 'ip'),
    Word('👂', 'oreja', 'ear', 'orelha', '귀', 'gwi'),
    Word('✋', 'mano', 'hand', 'mão', '손', 'son'),
    Word('🦶', 'pie', 'foot', 'pé', '발', 'bal'),
    Word('🦷', 'diente', 'tooth', 'dente', '이빨', 'ippal'),
  ]),
  Topic('clima', 'El cielo y el clima', '⛅', level: WordLevel.medio, [
    Word('☀️', 'sol', 'sun', 'sol', '해', 'hae'),
    Word('🌙', 'luna', 'moon', 'lua', '달', 'dal'),
    Word('⭐', 'estrella', 'star', 'estrela', '별', 'byeol'),
    Word('☁️', 'nube', 'cloud', 'nuvem', '구름', 'gureum'),
    Word('🌧️', 'lluvia', 'rain', 'chuva', '비', 'bi'),
    Word('❄️', 'nieve', 'snow', 'neve', '눈', 'nun'),
    Word('🌬️', 'viento', 'wind', 'vento', '바람', 'baram'),
    Word('🌈', 'arcoíris', 'rainbow', 'arco-íris', '무지개', 'mujigae'),
  ]),
  Topic('frutas', 'Frutas y verduras', '🥕', level: WordLevel.medio, [
    Word('🍓', 'frutilla', 'strawberry', 'morango', '딸기', 'ttalgi'),
    Word('🍇', 'uva', 'grapes', 'uva', '포도', 'podo'),
    Word('🍉', 'sandía', 'watermelon', 'melancia', '수박', 'subak'),
    Word('🍊', 'mandarina', 'tangerine', 'tangerina', '귤', 'gyul'),
    Word('🥕', 'zanahoria', 'carrot', 'cenoura', '당근', 'danggeun'),
    Word('🍅', 'tomate', 'tomato', 'tomate', '토마토', 'tomato'),
    Word('🥔', 'papa', 'potato', 'batata', '감자', 'gamja'),
    Word('🌽', 'choclo', 'corn', 'milho', '옥수수', 'oksusu'),
  ]),
  Topic('acciones', 'Acciones', '🏃', level: WordLevel.medio, [
    Word('🍽️', 'comer', 'to eat', 'comer', '먹다', 'meokda'),
    Word('🥤', 'tomar', 'to drink', 'beber', '마시다', 'masida'),
    Word('😴', 'dormir', 'to sleep', 'dormir', '자다', 'jada'),
    Word('🏃', 'correr', 'to run', 'correr', '달리다', 'dallida'),
    Word('📖', 'leer', 'to read', 'ler', '읽다', 'ikda'),
    Word('✍️', 'escribir', 'to write', 'escrever', '쓰다', 'sseuda'),
    Word('🧸', 'jugar', 'to play', 'brincar', '놀다', 'nolda'),
    Word('🎤', 'cantar', 'to sing', 'cantar', '노래하다', 'noraehada'),
  ]),
  Topic('lugares', 'Lugares', '🗺️', level: WordLevel.medio, [
    Word('🌳', 'parque', 'park', 'parque', '공원', 'gongwon'),
    Word('🏥', 'hospital', 'hospital', 'hospital', '병원', 'byeongwon'),
    Word('🛒', 'supermercado', 'supermarket', 'supermercado', '슈퍼마켓', 'syupeomaket'),
    Word('🏖️', 'playa', 'beach', 'praia', '해변', 'haebyeon'),
    Word('📚', 'biblioteca', 'library', 'biblioteca', '도서관', 'doseogwan'),
    Word('🍴', 'restaurante', 'restaurant', 'restaurante', '식당', 'sikdang'),
    Word('🎬', 'cine', 'cinema', 'cinema', '영화관', 'yeonghwagwan'),
    Word('🏙️', 'ciudad', 'city', 'cidade', '도시', 'dosi'),
  ]),
  Topic('transporte', 'Transporte', '🚗', level: WordLevel.medio, [
    Word('🚗', 'auto', 'car', 'carro', '자동차', 'jadongcha'),
    Word('🚌', 'colectivo', 'bus', 'ônibus', '버스', 'beoseu'),
    Word('🚲', 'bicicleta', 'bicycle', 'bicicleta', '자전거', 'jajeongeo'),
    Word('✈️', 'avión', 'airplane', 'avião', '비행기', 'bihaenggi'),
    Word('⛵', 'barco', 'boat', 'barco', '배', 'bae'),
    Word('🚆', 'tren', 'train', 'trem', '기차', 'gicha'),
    Word('🏍️', 'moto', 'motorcycle', 'moto', '오토바이', 'otobai'),
    Word('🚁', 'helicóptero', 'helicopter', 'helicóptero', '헬리콥터', 'hellikopteo'),
  ]),
  Topic('juguetes', 'Juguetes', '🧸', level: WordLevel.medio, [
    Word('⚽', 'pelota', 'ball', 'bola', '공', 'gong'),
    Word('🪆', 'muñeca', 'doll', 'boneca', '인형', 'inhyeong'),
    Word('🧩', 'rompecabezas', 'puzzle', 'quebra-cabeça', '퍼즐', 'peojeul'),
    Word('🪁', 'barrilete', 'kite', 'pipa', '연', 'yeon'),
    Word('🎈', 'globo', 'balloon', 'balão', '풍선', 'pungseon'),
    Word('🎲', 'dado', 'dice', 'dado', '주사위', 'jusawi'),
    Word('🪀', 'yoyó', 'yo-yo', 'ioiô', '요요', 'yoyo'),
    Word('🤖', 'robot', 'robot', 'robô', '로봇', 'robot'),
  ]),
  Topic('deportes', 'Deportes', '🏅', level: WordLevel.medio, [
    Word('⚽', 'fútbol', 'soccer', 'futebol', '축구', 'chukgu'),
    Word('🏀', 'básquet', 'basketball', 'basquete', '농구', 'nonggu'),
    Word('🎾', 'tenis', 'tennis', 'tênis', '테니스', 'teniseu'),
    Word('🏊', 'natación', 'swimming', 'natação', '수영', 'suyeong'),
    Word('🏐', 'vóley', 'volleyball', 'vôlei', '배구', 'baegu'),
    Word('⛸️', 'patinaje', 'skating', 'patinação', '스케이트', 'seukeiteu'),
    Word('🥋', 'karate', 'karate', 'caratê', '가라테', 'garate'),
    Word('🏓', 'ping-pong', 'table tennis', 'pingue-pongue', '탁구', 'takgu'),
  ]),
  Topic('profesiones', 'Profesiones', '🧑‍🚒', level: WordLevel.medio, [
    Word('🧑‍⚕️', 'médico', 'doctor', 'médico', '의사', 'uisa'),
    Word('🧑‍🚒', 'bombero', 'firefighter', 'bombeiro', '소방관', 'sobanggwan'),
    Word('👮', 'policía', 'police officer', 'policial', '경찰관', 'gyeongchalgwan'),
    Word('🧑‍🍳', 'cocinero', 'cook', 'cozinheiro', '요리사', 'yorisa'),
    Word('🧑‍🌾', 'granjero', 'farmer', 'fazendeiro', '농부', 'nongbu'),
    Word('🧑‍🚀', 'astronauta', 'astronaut', 'astronauta', '우주비행사', 'ujubihaengsa'),
    Word('🧑‍🎨', 'pintor', 'painter', 'pintor', '화가', 'hwaga'),
    Word('🧑‍🏫', 'maestro', 'teacher', 'professor', '선생님', 'seonsaengnim'),
  ]),
  // ---------------------------------------------------------- nivel avanzado
  Topic('frases', 'Frases útiles', '💬', level: WordLevel.avanzado, [
    Word('👋', 'hola', 'hello', 'olá', '안녕하세요', 'annyeonghaseyo'),
    Word('🙏', 'gracias', 'thank you', 'obrigado', '감사합니다', 'gamsahamnida'),
    Word('🥺', 'por favor', 'please', 'por favor', '부탁해요', 'butakaeyo'),
    Word('😔', 'perdón', 'sorry', 'desculpa', '미안해요', 'mianhaeyo'),
    Word('🌅', 'buen día', 'good morning', 'bom dia', '좋은 아침', 'joeun achim'),
    Word('🌙', 'buenas noches', 'good night', 'boa noite', '잘 자요', 'jal jayo'),
    Word('❤️', 'te quiero', 'I love you', 'eu te amo', '사랑해요', 'saranghaeyo'),
    Word('🤔', '¿cómo estás?', 'how are you?', 'tudo bem?', '잘 지내요?', 'jal jinaeyo?'),
  ]),
  Topic('dias', 'Días de la semana', '📅', level: WordLevel.avanzado, [
    Word('1️⃣', 'lunes', 'Monday', 'segunda-feira', '월요일', 'woryoil'),
    Word('2️⃣', 'martes', 'Tuesday', 'terça-feira', '화요일', 'hwayoil'),
    Word('3️⃣', 'miércoles', 'Wednesday', 'quarta-feira', '수요일', 'suyoil'),
    Word('4️⃣', 'jueves', 'Thursday', 'quinta-feira', '목요일', 'mogyoil'),
    Word('5️⃣', 'viernes', 'Friday', 'sexta-feira', '금요일', 'geumyoil'),
    Word('6️⃣', 'sábado', 'Saturday', 'sábado', '토요일', 'toyoil'),
    Word('7️⃣', 'domingo', 'Sunday', 'domingo', '일요일', 'iryoil'),
  ]),
  Topic('emociones', 'Emociones', '😊', level: WordLevel.avanzado, [
    Word('😀', 'feliz', 'happy', 'feliz', '행복해요', 'haengbokhaeyo'),
    Word('😢', 'triste', 'sad', 'triste', '슬퍼요', 'seulpeoyo'),
    Word('😠', 'enojado', 'angry', 'bravo', '화나요', 'hwanayo'),
    Word('🥱', 'cansado', 'tired', 'cansado', '피곤해요', 'pigonhaeyo'),
    Word('😨', 'asustado', 'scared', 'assustado', '무서워요', 'museowoyo'),
    Word('😮', 'sorprendido', 'surprised', 'surpreso', '놀랐어요', 'nollasseoyo'),
  ]),
];

Topic topicById(String id) => topics.firstWhere((t) => t.id == id, orElse: () => topics.first);

/// Lee un tema de un paquete (JSON de Firestore o guardado en el teléfono).
Topic? topicFromJson(Map<String, dynamic> j) {
  final id = j['id'] as String?;
  final words = j['words'];
  if (id == null || words is! List || words.length < 4) return null;
  return Topic(
    id,
    j['label'] as String? ?? id,
    j['emoji'] as String? ?? '📦',
    [
      for (final w in words)
        if (w is Map && w['es'] != null && w['en'] != null && w['pt'] != null && w['ko'] != null)
          Word(w['emoji'] as String? ?? '⭐', w['es'] as String, w['en'] as String, w['pt'] as String, w['ko'] as String,
              w['ko_r'] as String? ?? ''),
    ],
    level: WordLevel.values.asNameMap()[j['level']] ?? WordLevel.medio,
    pack: true,
  );
}

/// Palabras de los niveles libres, para la palabra del día.
List<Word> get allWords => [for (final t in builtInTopics) if (t.level != WordLevel.avanzado) ...t.words];

/// Palabra del día: la misma para toda la familia en un mismo día.
({Word word, Lang lang}) wordOfTheDay(DateTime day, List<Lang> langs) {
  final n = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays.abs();
  final lang = langs.isEmpty ? Lang.en : langs[n % langs.length];
  return (word: allWords[(n * 7) % allWords.length], lang: lang);
}
