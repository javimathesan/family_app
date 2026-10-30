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

class Topic {
  const Topic(this.id, this.label, this.emoji, this.words);
  final String id;
  final String label;
  final String emoji;
  final List<Word> words;
}

/// Vocabulario básico por temas.
const topics = [
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
];

Topic topicById(String id) => topics.firstWhere((t) => t.id == id, orElse: () => topics.first);

/// Todas las palabras, para la palabra del día.
final allWords = [for (final t in topics) ...t.words];

/// Palabra del día: la misma para toda la familia en un mismo día.
({Word word, Lang lang}) wordOfTheDay(DateTime day, List<Lang> langs) {
  final n = DateTime(day.year, day.month, day.day).difference(DateTime(2026)).inDays.abs();
  final lang = langs.isEmpty ? Lang.en : langs[n % langs.length];
  return (word: allWords[(n * 7) % allWords.length], lang: lang);
}
