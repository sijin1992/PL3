// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Item.proto

#define INTERNAL_SUPPRESS_PROTOBUF_FIELD_DEPRECATION
#include "Item.pb.h"

#include <algorithm>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/wire_format_lite_inl.h>
// @@protoc_insertion_point(includes)

void protobuf_ShutdownFile_Item_2eproto() {
  delete Pair::default_instance_;
  delete Item::default_instance_;
  delete ItemList::default_instance_;
  delete GeneralGoods::default_instance_;
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
void protobuf_AddDesc_Item_2eproto_impl() {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#else
void protobuf_AddDesc_Item_2eproto() {
  static bool already_here = false;
  if (already_here) return;
  already_here = true;
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#endif
  Pair::default_instance_ = new Pair();
  Item::default_instance_ = new Item();
  ItemList::default_instance_ = new ItemList();
  GeneralGoods::default_instance_ = new GeneralGoods();
  Pair::default_instance_->InitAsDefaultInstance();
  Item::default_instance_->InitAsDefaultInstance();
  ItemList::default_instance_->InitAsDefaultInstance();
  GeneralGoods::default_instance_->InitAsDefaultInstance();
  ::google::protobuf::internal::OnShutdown(&protobuf_ShutdownFile_Item_2eproto);
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
GOOGLE_PROTOBUF_DECLARE_ONCE(protobuf_AddDesc_Item_2eproto_once_);
void protobuf_AddDesc_Item_2eproto() {
  ::google::protobuf::::google::protobuf::GoogleOnceInit(&protobuf_AddDesc_Item_2eproto_once_,
                 &protobuf_AddDesc_Item_2eproto_impl);
}
#else
// Force AddDescriptors() to be called at static initialization time.
struct StaticDescriptorInitializer_Item_2eproto {
  StaticDescriptorInitializer_Item_2eproto() {
    protobuf_AddDesc_Item_2eproto();
  }
} static_descriptor_initializer_Item_2eproto_;
#endif

// ===================================================================

#ifndef _MSC_VER
const int Pair::kKeyFieldNumber;
const int Pair::kValueFieldNumber;
#endif  // !_MSC_VER

Pair::Pair()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void Pair::InitAsDefaultInstance() {
}

Pair::Pair(const Pair& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void Pair::SharedCtor() {
  _cached_size_ = 0;
  key_ = 0;
  value_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

Pair::~Pair() {
  SharedDtor();
}

void Pair::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
  }
}

void Pair::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const Pair& Pair::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Item_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Item_2eproto();
#endif
  return *default_instance_;
}

Pair* Pair::default_instance_ = NULL;

Pair* Pair::New() const {
  return new Pair;
}

void Pair::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    key_ = 0;
    value_ = 0;
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool Pair::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // required int32 key = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &key_)));
          set_has_key();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(16)) goto parse_value;
        break;
      }

      // required int32 value = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_value:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &value_)));
          set_has_value();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectAtEnd()) return true;
        break;
      }

      default: {
      handle_uninterpreted:
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_END_GROUP) {
          return true;
        }
        DO_(::google::protobuf::internal::WireFormatLite::SkipField(input, tag));
        break;
      }
    }
  }
  return true;
#undef DO_
}

void Pair::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 key = 1;
  if (has_key()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->key(), output);
  }

  // required int32 value = 2;
  if (has_value()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->value(), output);
  }

}

int Pair::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // required int32 key = 1;
    if (has_key()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->key());
    }

    // required int32 value = 2;
    if (has_value()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->value());
    }

  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void Pair::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const Pair*>(&from));
}

void Pair::MergeFrom(const Pair& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_key()) {
      set_key(from.key());
    }
    if (from.has_value()) {
      set_value(from.value());
    }
  }
}

void Pair::CopyFrom(const Pair& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool Pair::IsInitialized() const {
  if ((_has_bits_[0] & 0x00000003) != 0x00000003) return false;

  return true;
}

void Pair::Swap(Pair* other) {
  if (other != this) {
    std::swap(key_, other->key_);
    std::swap(value_, other->value_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string Pair::GetTypeName() const {
  return "Pair";
}


// ===================================================================

#ifndef _MSC_VER
const int Item::kIdFieldNumber;
const int Item::kNumFieldNumber;
const int Item::kGuidFieldNumber;
#endif  // !_MSC_VER

Item::Item()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void Item::InitAsDefaultInstance() {
}

Item::Item(const Item& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void Item::SharedCtor() {
  _cached_size_ = 0;
  id_ = 0;
  num_ = 0;
  guid_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

Item::~Item() {
  SharedDtor();
}

void Item::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
  }
}

void Item::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const Item& Item::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Item_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Item_2eproto();
#endif
  return *default_instance_;
}

Item* Item::default_instance_ = NULL;

Item* Item::New() const {
  return new Item;
}

void Item::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    id_ = 0;
    num_ = 0;
    guid_ = 0;
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool Item::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // required int32 id = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &id_)));
          set_has_id();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(16)) goto parse_num;
        break;
      }

      // required int32 num = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_num:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &num_)));
          set_has_num();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(24)) goto parse_guid;
        break;
      }

      // required int32 guid = 3;
      case 3: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_guid:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &guid_)));
          set_has_guid();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectAtEnd()) return true;
        break;
      }

      default: {
      handle_uninterpreted:
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_END_GROUP) {
          return true;
        }
        DO_(::google::protobuf::internal::WireFormatLite::SkipField(input, tag));
        break;
      }
    }
  }
  return true;
#undef DO_
}

void Item::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 id = 1;
  if (has_id()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->id(), output);
  }

  // required int32 num = 2;
  if (has_num()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->num(), output);
  }

  // required int32 guid = 3;
  if (has_guid()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(3, this->guid(), output);
  }

}

int Item::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // required int32 id = 1;
    if (has_id()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->id());
    }

    // required int32 num = 2;
    if (has_num()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->num());
    }

    // required int32 guid = 3;
    if (has_guid()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->guid());
    }

  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void Item::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const Item*>(&from));
}

void Item::MergeFrom(const Item& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_id()) {
      set_id(from.id());
    }
    if (from.has_num()) {
      set_num(from.num());
    }
    if (from.has_guid()) {
      set_guid(from.guid());
    }
  }
}

void Item::CopyFrom(const Item& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool Item::IsInitialized() const {
  if ((_has_bits_[0] & 0x00000007) != 0x00000007) return false;

  return true;
}

void Item::Swap(Item* other) {
  if (other != this) {
    std::swap(id_, other->id_);
    std::swap(num_, other->num_);
    std::swap(guid_, other->guid_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string Item::GetTypeName() const {
  return "Item";
}


// ===================================================================

#ifndef _MSC_VER
const int ItemList::kItemListFieldNumber;
#endif  // !_MSC_VER

ItemList::ItemList()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void ItemList::InitAsDefaultInstance() {
}

ItemList::ItemList(const ItemList& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void ItemList::SharedCtor() {
  _cached_size_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

ItemList::~ItemList() {
  SharedDtor();
}

void ItemList::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
  }
}

void ItemList::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const ItemList& ItemList::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Item_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Item_2eproto();
#endif
  return *default_instance_;
}

ItemList* ItemList::default_instance_ = NULL;

ItemList* ItemList::New() const {
  return new ItemList;
}

void ItemList::Clear() {
  item_list_.Clear();
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool ItemList::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // repeated .Item item_list = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_LENGTH_DELIMITED) {
         parse_item_list:
          DO_(::google::protobuf::internal::WireFormatLite::ReadMessageNoVirtual(
                input, add_item_list()));
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(10)) goto parse_item_list;
        if (input->ExpectAtEnd()) return true;
        break;
      }

      default: {
      handle_uninterpreted:
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_END_GROUP) {
          return true;
        }
        DO_(::google::protobuf::internal::WireFormatLite::SkipField(input, tag));
        break;
      }
    }
  }
  return true;
#undef DO_
}

void ItemList::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // repeated .Item item_list = 1;
  for (int i = 0; i < this->item_list_size(); i++) {
    ::google::protobuf::internal::WireFormatLite::WriteMessage(
      1, this->item_list(i), output);
  }

}

int ItemList::ByteSize() const {
  int total_size = 0;

  // repeated .Item item_list = 1;
  total_size += 1 * this->item_list_size();
  for (int i = 0; i < this->item_list_size(); i++) {
    total_size +=
      ::google::protobuf::internal::WireFormatLite::MessageSizeNoVirtual(
        this->item_list(i));
  }

  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void ItemList::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const ItemList*>(&from));
}

void ItemList::MergeFrom(const ItemList& from) {
  GOOGLE_CHECK_NE(&from, this);
  item_list_.MergeFrom(from.item_list_);
}

void ItemList::CopyFrom(const ItemList& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool ItemList::IsInitialized() const {

  for (int i = 0; i < item_list_size(); i++) {
    if (!this->item_list(i).IsInitialized()) return false;
  }
  return true;
}

void ItemList::Swap(ItemList* other) {
  if (other != this) {
    item_list_.Swap(&other->item_list_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string ItemList::GetTypeName() const {
  return "ItemList";
}


// ===================================================================

#ifndef _MSC_VER
const int GeneralGoods::kItemFieldNumber;
const int GeneralGoods::kCostFieldNumber;
#endif  // !_MSC_VER

GeneralGoods::GeneralGoods()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void GeneralGoods::InitAsDefaultInstance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  item_ = const_cast< ::Item*>(
      ::Item::internal_default_instance());
#else
  item_ = const_cast< ::Item*>(&::Item::default_instance());
#endif
}

GeneralGoods::GeneralGoods(const GeneralGoods& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void GeneralGoods::SharedCtor() {
  _cached_size_ = 0;
  item_ = NULL;
  cost_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

GeneralGoods::~GeneralGoods() {
  SharedDtor();
}

void GeneralGoods::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
    delete item_;
  }
}

void GeneralGoods::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const GeneralGoods& GeneralGoods::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Item_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Item_2eproto();
#endif
  return *default_instance_;
}

GeneralGoods* GeneralGoods::default_instance_ = NULL;

GeneralGoods* GeneralGoods::New() const {
  return new GeneralGoods;
}

void GeneralGoods::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (has_item()) {
      if (item_ != NULL) item_->::Item::Clear();
    }
    cost_ = 0;
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool GeneralGoods::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // optional .Item item = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_LENGTH_DELIMITED) {
          DO_(::google::protobuf::internal::WireFormatLite::ReadMessageNoVirtual(
               input, mutable_item()));
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(16)) goto parse_cost;
        break;
      }

      // optional int32 cost = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_cost:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &cost_)));
          set_has_cost();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectAtEnd()) return true;
        break;
      }

      default: {
      handle_uninterpreted:
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_END_GROUP) {
          return true;
        }
        DO_(::google::protobuf::internal::WireFormatLite::SkipField(input, tag));
        break;
      }
    }
  }
  return true;
#undef DO_
}

void GeneralGoods::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // optional .Item item = 1;
  if (has_item()) {
    ::google::protobuf::internal::WireFormatLite::WriteMessage(
      1, this->item(), output);
  }

  // optional int32 cost = 2;
  if (has_cost()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->cost(), output);
  }

}

int GeneralGoods::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // optional .Item item = 1;
    if (has_item()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::MessageSizeNoVirtual(
          this->item());
    }

    // optional int32 cost = 2;
    if (has_cost()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->cost());
    }

  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void GeneralGoods::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const GeneralGoods*>(&from));
}

void GeneralGoods::MergeFrom(const GeneralGoods& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_item()) {
      mutable_item()->::Item::MergeFrom(from.item());
    }
    if (from.has_cost()) {
      set_cost(from.cost());
    }
  }
}

void GeneralGoods::CopyFrom(const GeneralGoods& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool GeneralGoods::IsInitialized() const {

  if (has_item()) {
    if (!this->item().IsInitialized()) return false;
  }
  return true;
}

void GeneralGoods::Swap(GeneralGoods* other) {
  if (other != this) {
    std::swap(item_, other->item_);
    std::swap(cost_, other->cost_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string GeneralGoods::GetTypeName() const {
  return "GeneralGoods";
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)