class RingBuffer<T> {
  RingBuffer(this.capacity) : _buf = List<T?>.filled(capacity, null);

  final int capacity;
  final List<T?> _buf;
  int _head = 0;
  int _size = 0;

  void add(T value) {
    _buf[_head] = value;
    _head = (_head + 1) % capacity;
    if (_size < capacity) _size++;
  }

  List<T> get values {
    if (_size == 0) return [];
    final result = <T>[];
    final start = _size < capacity ? 0 : _head;
    for (var i = 0; i < _size; i++) {
      result.add(_buf[(start + i) % capacity] as T);
    }
    return result;
  }

  int get length => _size;
  bool get isEmpty => _size == 0;
}
