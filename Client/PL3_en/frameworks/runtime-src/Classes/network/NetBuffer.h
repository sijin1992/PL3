//
//  NetBuffer.h
//  hellogame
//
//  Created by hankai on 16/2/26.
//
//

#ifndef NetBuffer_h
#define NetBuffer_h

#include "cocos2d.h"

class NetBuffer {
public:
    static const size_t kCheapPrepend = 8;
    static const size_t kInitialSize = 1024;
    
    NetBuffer()
    : _buffer(kCheapPrepend + kInitialSize),
    _readerIndex(kCheapPrepend),
    _writerIndex(kCheapPrepend)
    {
        assert(readableBytes() == 0);
        assert(writableBytes() == kInitialSize);
        assert(prependableBytes() == kCheapPrepend);
    }
    
    size_t readableBytes() const
    { return _writerIndex - _readerIndex; }
    
    size_t writableBytes() const
    { return _buffer.size() - _writerIndex; }
    
    size_t prependableBytes() const
    { return _readerIndex; }
    
    const char* peek() const
    { return begin() + _readerIndex; }
    
    void retrieve(size_t len)
    {
        assert(len <= readableBytes());
        if (len < readableBytes())
        {
            _readerIndex += len;
        }
        else
        {
            retrieveAll();
        }
    }
    
    void retrieveInt32()
    {
        retrieve(sizeof(int32_t));
    }
    
    void retrieveInt16()
    {
        retrieve(sizeof(int16_t));
    }
    
    void retrieveInt8()
    {
        retrieve(sizeof(int8_t));
    }
    
    void retrieveAll()
    {
        _readerIndex = kCheapPrepend;
        _writerIndex = kCheapPrepend;
    }
    
    ///
    /// Peek int32_t from network endian
    ///
    /// Require: buf->readableBytes() >= sizeof(int32_t)
    int32_t peekInt32() const
    {
        assert(readableBytes() >= sizeof(int32_t));
        int32_t be32 = 0;
        ::memcpy(&be32, peek(), sizeof be32);
        return CC_SWAP_INT32_LITTLE_TO_HOST(be32);
    }
    
    int16_t peekInt16() const
    {
        assert(readableBytes() >= sizeof(int16_t));
        int16_t be16 = 0;
        ::memcpy(&be16, peek(), sizeof be16);
        return CC_SWAP_INT16_LITTLE_TO_HOST(be16);
    }
    
    int8_t peekInt8() const
    {
        assert(readableBytes() >= sizeof(int8_t));
        int8_t x = *peek();
        return x;
    }
    
    ///
    /// Read int32_t from network endian
    ///
    /// Require: buf->readableBytes() >= sizeof(int32_t)
    int32_t readInt32()
    {
        int32_t result = peekInt32();
        retrieveInt32();
        return result;
    }
    
    int16_t readInt16()
    {
        int16_t result = peekInt16();
        retrieveInt16();
        return result;
    }
    
    int8_t readInt8()
    {
        int8_t result = peekInt8();
        retrieveInt8();
        return result;
    }
    
    void append(const char* /*restrict*/ data, size_t len)
    {
        if(!data){
            return;
        }
        ensureWritableBytes(len);
        std::copy(data, data+len, beginWrite());
        hasWritten(len);
    }
    
    void prepend(const void* /*restrict*/ data, size_t len)
    {
        if(!data){
            return;
        }
        assert(len <= prependableBytes());
        _readerIndex -= len;
        const char* d = static_cast<const char*>(data);
        std::copy(d, d+len, begin()+ _readerIndex);
    }
    
    char* beginWrite()
    { return begin() + _writerIndex; }
    
    const char* beginWrite() const
    { return begin() + _writerIndex; }
    
    void hasWritten(size_t len)
    {
        assert(len <= writableBytes());
        _writerIndex += len;
    }
    
    void unwrite(size_t len)
    {
        assert(len <= readableBytes());
        _writerIndex -= len;
    }
    
    void ensureWritableBytes(size_t len)
    {
        if (writableBytes() < len)
        {
            makeSpace(len);
        }
        assert(writableBytes() >= len);
    }
    
    
    void shrink(size_t reserve)
    {
        // FIXME: use vector::shrink_to_fit() in C++ 11 if possible.
        _buffer.shrink_to_fit();
    }
    
    size_t internalCapacity() const
    {
        return _buffer.capacity();
    }
private:
    
    char* begin()
    { return &*_buffer.begin(); }
    
    const char* begin() const
    { return &*_buffer.begin(); }
    
    void makeSpace(size_t len)
    {
        if (writableBytes() + prependableBytes() < len + kCheapPrepend)
        {
            // FIXME: move readable data
            _buffer.resize(_writerIndex+len);
        }
        else
        {
            // move readable data to the front, make space inside buffer
            assert(kCheapPrepend < _readerIndex);
            size_t readable = readableBytes();
            std::copy(begin()+_readerIndex,
                      begin()+_writerIndex,
                      begin()+kCheapPrepend);
            _readerIndex = kCheapPrepend;
            _writerIndex = _readerIndex + readable;
            assert(readable == readableBytes());
        }
    }
    
private:
    std::vector<char> _buffer;
    size_t _readerIndex;
    size_t _writerIndex;
};

#endif /* NetBuffer_h */
