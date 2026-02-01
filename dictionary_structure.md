# Dictionary Entry Structure

## Overview
Cấu trúc lưu trữ từ/cụm từ trong từ điển, hỗ trợ cả từ đơn ("run") và cụm từ ("give up", "break down"). Mỗi entry giới hạn tối đa **10 definitions** để tránh quá tải thông tin.

## Data Structure

```json
{
  "word": "string",           // Từ hoặc cụm từ (e.g., "run", "give up")
  "phonetics": [              // Danh sách phiên âm (IPA)
    {
      "text": "string",         // Phiên âm IPA (e.g., "/rʌn/")
      "tag": "string?"        // Optional: UK, US, etc.
    }
  ],
  "forms": [                  // Optional: Các dạng biến thể của từ
    {
      "word": "string",       // Dạng biến thể (e.g., "runs", "running")
      "tags": ["string"]      // Nhãn: present, past, participle, etc.
    }
  ],
  "meanings": [               // Danh sách meanings theo part of speech
    {
      "partOfSpeech": "string",  // verb, noun, adjective, etc.
      "synonyms": ["string"],    // Optional: Từ đồng nghĩa (meaning level)
      "antonyms": ["string"],    // Optional: Từ trái nghĩa (meaning level)
      "definitions": [           // Tối đa 10 definitions
        {
          "definition": "string",  // Định nghĩa chính (English only)
          "example": "string?",    // Optional: Ví dụ sử dụng
          "synonyms": ["string"],  // Optional: Từ đồng nghĩa (definition level)
          "antonyms": ["string"]   // Optional: Từ trái nghĩa (definition level)
        }
      ]
    }
  ]
}
```

## Field Descriptions

### 1. `word` (required)
- **Type**: `string`
- **Description**: Từ hoặc cụm từ cần tra
- **Examples**: 
  - Single word: `"run"`, `"beautiful"`, `"quickly"`
  - Phrasal verb: `"give up"`, `"break down"`, `"look after"`
  - Idiom: `"piece of cake"`, `"break the ice"`

### 2. `phonetics` (optional array)
- **Type**: `array of objects`
- **Description**: Danh sách các phiên âm IPA
- **Fields**:
  - `text` (required): Phiên âm IPA
  - `tag` (optional): Nhãn phân biệt (UK, US, AU, etc.)
- **Example**:
```json
[
  { "text": "/rʌn/", "tag": "US" },
  { "text": "/rʊn/", "tag": "UK" }
]
```

### 3. `forms` (optional array)
- **Type**: `array of objects`
- **Description**: Các dạng biến thể của từ (verb conjugations, plural forms, etc.)
- **Fields**:
  - `word` (required): Dạng biến thể
  - `tags` (required): Mảng nhãn mô tả dạng biến thể
- **Common tags**:
  - Verb: `present`, `past`, `participle`, `infinitive`, `third-person`, `singular`, `plural`
  - Noun: `plural`, `singular`
  - Adjective: `comparative`, `superlative`
- **Example**:
```json
[
  { "word": "runs", "tags": ["present", "third-person", "singular"] },
  { "word": "running", "tags": ["participle", "present"] },
  { "word": "ran", "tags": ["past"] }
]
```
- **Note**: Field này thường chỉ có trong FreeDict API, các API khác không cung cấp

### 4. `meanings` (required array)
- **Type**: `array of objects`
- **Description**: Nhóm definitions theo part of speech
- **Fields**:
  - `partOfSpeech` (required): Loại từ
  - `synonyms` (optional): Từ đồng nghĩa ở cấp meaning
  - `antonyms` (optional): Từ trái nghĩa ở cấp meaning
  - `definitions` (required): Mảng definitions (max 10)

#### 4.1. `partOfSpeech` (required)
- **Type**: `string`
- **Common values**: 
  - `"verb"` - Động từ
  - `"noun"` - Danh từ
  - `"adjective"` - Tính từ
  - `"adverb"` - Trạng từ
  - `"preposition"` - Giới từ
  - `"conjunction"` - Liên từ
  - `"interjection"` - Thán từ
  - `"phrasal verb"` - Cụm động từ

#### 4.2. `synonyms` & `antonyms` (optional arrays)
- **Type**: `array of strings`
- **Description**: Từ đồng nghĩa và trái nghĩa
- **Levels**: Có thể xuất hiện ở 2 levels:
  - **Meaning level**: Áp dụng cho toàn bộ part of speech
  - **Definition level**: Áp dụng cho từng definition cụ thể
- **Example**:
```json
{
  "partOfSpeech": "noun",
  "synonyms": ["execute", "start", "tread"],
  "antonyms": ["rise", "riser"],
  "definitions": [...]
}
```
- **Note**: Hầu hết các API trả về mảng rỗng `[]` cho synonyms/antonyms

#### 4.3. `definitions` (required array, max 10 items)
- **Type**: `array of objects`
- **Max length**: **10 definitions** per part of speech
- **Fields**:
  - `definition` (required): Định nghĩa bằng tiếng Anh
  - `example` (optional): Câu ví dụ minh họa
  - `synonyms` (optional): Từ đồng nghĩa cho definition này
  - `antonyms` (optional): Từ trái nghĩa cho definition này

## Complete Example

### Example 1: Single Word - "run" (verb)

```json
{
  "word": "run",
  "phonetics": [
    { "text": "/rʌn/", "tag": "US" },
    { "text": "/rʊn/", "tag": "UK" }
  ],
  "forms": [
    { "word": "runs", "tags": ["present", "third-person", "singular"] },
    { "word": "running", "tags": ["participle", "present"] },
    { "word": "ran", "tags": ["past"] },
    { "word": "run", "tags": ["participle", "past"] }
  ],
  "meanings": [
    {
      "partOfSpeech": "verb",
      "synonyms": [],
      "antonyms": [],
      "definitions": [
        {
          "definition": "To move swiftly on foot",
          "example": "I run every morning for exercise.",
          "synonyms": ["sprint", "jog", "dash"],
          "antonyms": ["walk", "crawl"]
        },
        {
          "definition": "To operate or function",
          "example": "The engine runs smoothly.",
          "synonyms": ["operate", "function", "work"],
          "antonyms": ["stop", "halt"]
        },
        {
          "definition": "To manage or control",
          "example": "She runs a successful business.",
          "synonyms": ["manage", "operate", "direct"],
          "antonyms": []
        },
        {
          "definition": "To flow or cause to flow",
          "example": "Water runs from the tap.",
          "synonyms": ["flow", "stream", "pour"],
          "antonyms": []
        },
        {
          "definition": "To compete in a race or election",
          "example": "He's running for president.",
          "synonyms": ["compete", "campaign"],
          "antonyms": []
        },
        {
          "definition": "To continue or extend",
          "example": "The road runs along the coast.",
          "synonyms": ["extend", "stretch", "continue"],
          "antonyms": []
        },
        {
          "definition": "To cost a particular amount",
          "example": "The repairs will run you about $500.",
          "synonyms": ["cost"],
          "antonyms": []
        },
        {
          "definition": "To publish or broadcast",
          "example": "The newspaper ran the story on the front page.",
          "synonyms": ["publish", "print", "broadcast"],
          "antonyms": []
        },
        {
          "definition": "To transport someone or something",
          "example": "Can you run me to the station?",
          "synonyms": ["drive", "transport", "take"],
          "antonyms": []
        },
        {
          "definition": "To smuggle illegal goods",
          "example": "They were caught running drugs across the border.",
          "synonyms": ["smuggle", "traffic"],
          "antonyms": []
        }
      ]
    }
  ]
}
```

### Example 2: Phrasal Verb - "give up"

```json
{
  "word": "give up",
  "phonetics": [
    { "text": "/ɡɪv ʌp/" }
  ],
  "meanings": [
    {
      "partOfSpeech": "phrasal verb",
      "definitions": [
        {
          "definition": "To stop trying to do something",
          "example": "Don't give up! Keep trying."
        },
        {
          "definition": "To surrender or admit defeat",
          "example": "The soldiers refused to give up."
        },
        {
          "definition": "To stop doing or having something",
          "example": "I gave up smoking last year."
        },
        {
          "definition": "To allow someone else to have something",
          "example": "She gave up her seat to an elderly woman."
        },
        {
          "definition": "To devote time or attention to something",
          "example": "He gave up his weekend to help with the project."
        }
      ]
    }
  ]
}
```

### Example 3: Multiple Parts of Speech - "run" (noun)

```json
{
  "word": "run",
  "phonetics": [
    { "text": "/rʌn/" }
  ],
  "meanings": [
    {
      "partOfSpeech": "noun",
      "definitions": [
        {
          "definition": "An act of running",
          "example": "I went for a run this morning."
        },
        {
          "definition": "A journey or route",
          "example": "The bus makes its final run at midnight."
        },
        {
          "definition": "A continuous period",
          "example": "The play had a successful run on Broadway."
        },
        {
          "definition": "A sudden demand for something",
          "example": "There was a run on the banks."
        },
        {
          "definition": "A point scored in cricket or baseball",
          "example": "England scored 250 runs."
        },
        {
          "definition": "A vertical hole in stockings",
          "example": "I got a run in my tights."
        },
        {
          "definition": "An enclosure for animals",
          "example": "The chickens are in their run."
        },
        {
          "definition": "The usual or ordinary type",
          "example": "He's not your run-of-the-mill candidate."
        }
      ]
    }
  ]
}
```

## Implementation Notes

### 1. Definition Limit
- **Maximum 10 definitions** per `partOfSpeech`
- Nếu có nhiều hơn 10 definitions từ API, chọn 10 definitions phổ biến nhất
- Ưu tiên definitions có ví dụ (example)

### 2. Language
- **English only** - Không lưu translations sang ngôn ngữ khác
- Definitions phải bằng tiếng Anh
- Examples phải bằng tiếng Anh

### 3. Phonetics
- Sử dụng IPA (International Phonetic Alphabet)
- Có thể có nhiều phiên âm (UK, US, AU, etc.)
- Field `tag` giúp phân biệt các biến thể phát âm

### 4. Part of Speech Grouping
- Group definitions theo `partOfSpeech`
- Một từ có thể có nhiều `meanings` (verb, noun, adjective, etc.)
- Mỗi `meaning` có danh sách riêng tối đa 10 definitions

### 5. Examples
- Optional nhưng nên có để minh họa cách dùng
- Ngắn gọn, dễ hiểu
- Thể hiện context thực tế

## Storage Recommendations

### Database Schema (if using SQL)
```sql
CREATE TABLE words (
  id UUID PRIMARY KEY,
  word VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE phonetics (
  id UUID PRIMARY KEY,
  word_id UUID REFERENCES words(id),
  text VARCHAR(100) NOT NULL,
  tag VARCHAR(20)
);

CREATE TABLE meanings (
  id UUID PRIMARY KEY,
  word_id UUID REFERENCES words(id),
  part_of_speech VARCHAR(50) NOT NULL
);

CREATE TABLE definitions (
  id UUID PRIMARY KEY,
  meaning_id UUID REFERENCES meanings(id),
  definition TEXT NOT NULL,
  example TEXT,
  order_index INT NOT NULL  -- For maintaining order (1-10)
);
```

### NoSQL/JSON Storage
- Lưu trực tiếp dưới dạng JSON document
- Sử dụng `word` làm key/index
- Phù hợp với MongoDB, Firebase, etc.

## Validation Rules

1. ✅ `word` không được rỗng
2. ✅ `meanings` phải có ít nhất 1 item
3. ✅ Mỗi `meaning` phải có `partOfSpeech` và `definitions`
4. ✅ `definitions` không được rỗng
5. ✅ Mỗi `definition` phải có field `definition` (text)
6. ⚠️ Giới hạn tối đa 10 definitions per `partOfSpeech`
7. ⚠️ `phonetics` có thể rỗng (optional)
8. ⚠️ `example` có thể null (optional)
