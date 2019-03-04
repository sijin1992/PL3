// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Item.proto

#ifndef PROTOBUF_Item_2eproto__INCLUDED
#define PROTOBUF_Item_2eproto__INCLUDED

#include <string>

#include <google/protobuf/stubs/common.h>

#if GOOGLE_PROTOBUF_VERSION < 2005000
#error This file was generated by a newer version of protoc which is
#error incompatible with your Protocol Buffer headers.  Please update
#error your headers.
#endif
#if 2005000 < GOOGLE_PROTOBUF_MIN_PROTOC_VERSION
#error This file was generated by an older version of protoc which is
#error incompatible with your Protocol Buffer headers.  Please
#error regenerate this file with a newer version of protoc.
#endif

#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/message_lite.h>
#include <google/protobuf/repeated_field.h>
#include <google/protobuf/extension_set.h>
// @@protoc_insertion_point(includes)

// Internal implementation detail -- do not call these.
void  protobuf_AddDesc_Item_2eproto();
void protobuf_AssignDesc_Item_2eproto();
void protobuf_ShutdownFile_Item_2eproto();

class Pair;
class Item;
class ItemList;
class GeneralGoods;

// ===================================================================

class Pair : public ::google::protobuf::MessageLite {
 public:
  Pair();
  virtual ~Pair();

  Pair(const Pair& from);

  inline Pair& operator=(const Pair& from) {
    CopyFrom(from);
    return *this;
  }

  static const Pair& default_instance();

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  // Returns the internal default instance pointer. This function can
  // return NULL thus should not be used by the user. This is intended
  // for Protobuf internal code. Please use default_instance() declared
  // above instead.
  static inline const Pair* internal_default_instance() {
    return default_instance_;
  }
  #endif

  void Swap(Pair* other);

  // implements Message ----------------------------------------------

  Pair* New() const;
  void CheckTypeAndMergeFrom(const ::google::protobuf::MessageLite& from);
  void CopyFrom(const Pair& from);
  void MergeFrom(const Pair& from);
  void Clear();
  bool IsInitialized() const;

  int ByteSize() const;
  bool MergePartialFromCodedStream(
      ::google::protobuf::io::CodedInputStream* input);
  void SerializeWithCachedSizes(
      ::google::protobuf::io::CodedOutputStream* output) const;
  int GetCachedSize() const { return _cached_size_; }
  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const;
  public:

  ::std::string GetTypeName() const;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  // required int32 key = 1;
  inline bool has_key() const;
  inline void clear_key();
  static const int kKeyFieldNumber = 1;
  inline ::google::protobuf::int32 key() const;
  inline void set_key(::google::protobuf::int32 value);

  // required int32 value = 2;
  inline bool has_value() const;
  inline void clear_value();
  static const int kValueFieldNumber = 2;
  inline ::google::protobuf::int32 value() const;
  inline void set_value(::google::protobuf::int32 value);

  // @@protoc_insertion_point(class_scope:Pair)
 private:
  inline void set_has_key();
  inline void clear_has_key();
  inline void set_has_value();
  inline void clear_has_value();

  ::google::protobuf::int32 key_;
  ::google::protobuf::int32 value_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(2 + 31) / 32];

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  friend void  protobuf_AddDesc_Item_2eproto_impl();
  #else
  friend void  protobuf_AddDesc_Item_2eproto();
  #endif
  friend void protobuf_AssignDesc_Item_2eproto();
  friend void protobuf_ShutdownFile_Item_2eproto();

  void InitAsDefaultInstance();
  static Pair* default_instance_;
};
// -------------------------------------------------------------------

class Item : public ::google::protobuf::MessageLite {
 public:
  Item();
  virtual ~Item();

  Item(const Item& from);

  inline Item& operator=(const Item& from) {
    CopyFrom(from);
    return *this;
  }

  static const Item& default_instance();

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  // Returns the internal default instance pointer. This function can
  // return NULL thus should not be used by the user. This is intended
  // for Protobuf internal code. Please use default_instance() declared
  // above instead.
  static inline const Item* internal_default_instance() {
    return default_instance_;
  }
  #endif

  void Swap(Item* other);

  // implements Message ----------------------------------------------

  Item* New() const;
  void CheckTypeAndMergeFrom(const ::google::protobuf::MessageLite& from);
  void CopyFrom(const Item& from);
  void MergeFrom(const Item& from);
  void Clear();
  bool IsInitialized() const;

  int ByteSize() const;
  bool MergePartialFromCodedStream(
      ::google::protobuf::io::CodedInputStream* input);
  void SerializeWithCachedSizes(
      ::google::protobuf::io::CodedOutputStream* output) const;
  int GetCachedSize() const { return _cached_size_; }
  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const;
  public:

  ::std::string GetTypeName() const;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  // required int32 id = 1;
  inline bool has_id() const;
  inline void clear_id();
  static const int kIdFieldNumber = 1;
  inline ::google::protobuf::int32 id() const;
  inline void set_id(::google::protobuf::int32 value);

  // required int32 num = 2;
  inline bool has_num() const;
  inline void clear_num();
  static const int kNumFieldNumber = 2;
  inline ::google::protobuf::int32 num() const;
  inline void set_num(::google::protobuf::int32 value);

  // required int32 guid = 3;
  inline bool has_guid() const;
  inline void clear_guid();
  static const int kGuidFieldNumber = 3;
  inline ::google::protobuf::int32 guid() const;
  inline void set_guid(::google::protobuf::int32 value);

  // @@protoc_insertion_point(class_scope:Item)
 private:
  inline void set_has_id();
  inline void clear_has_id();
  inline void set_has_num();
  inline void clear_has_num();
  inline void set_has_guid();
  inline void clear_has_guid();

  ::google::protobuf::int32 id_;
  ::google::protobuf::int32 num_;
  ::google::protobuf::int32 guid_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(3 + 31) / 32];

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  friend void  protobuf_AddDesc_Item_2eproto_impl();
  #else
  friend void  protobuf_AddDesc_Item_2eproto();
  #endif
  friend void protobuf_AssignDesc_Item_2eproto();
  friend void protobuf_ShutdownFile_Item_2eproto();

  void InitAsDefaultInstance();
  static Item* default_instance_;
};
// -------------------------------------------------------------------

class ItemList : public ::google::protobuf::MessageLite {
 public:
  ItemList();
  virtual ~ItemList();

  ItemList(const ItemList& from);

  inline ItemList& operator=(const ItemList& from) {
    CopyFrom(from);
    return *this;
  }

  static const ItemList& default_instance();

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  // Returns the internal default instance pointer. This function can
  // return NULL thus should not be used by the user. This is intended
  // for Protobuf internal code. Please use default_instance() declared
  // above instead.
  static inline const ItemList* internal_default_instance() {
    return default_instance_;
  }
  #endif

  void Swap(ItemList* other);

  // implements Message ----------------------------------------------

  ItemList* New() const;
  void CheckTypeAndMergeFrom(const ::google::protobuf::MessageLite& from);
  void CopyFrom(const ItemList& from);
  void MergeFrom(const ItemList& from);
  void Clear();
  bool IsInitialized() const;

  int ByteSize() const;
  bool MergePartialFromCodedStream(
      ::google::protobuf::io::CodedInputStream* input);
  void SerializeWithCachedSizes(
      ::google::protobuf::io::CodedOutputStream* output) const;
  int GetCachedSize() const { return _cached_size_; }
  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const;
  public:

  ::std::string GetTypeName() const;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  // repeated .Item item_list = 1;
  inline int item_list_size() const;
  inline void clear_item_list();
  static const int kItemListFieldNumber = 1;
  inline const ::Item& item_list(int index) const;
  inline ::Item* mutable_item_list(int index);
  inline ::Item* add_item_list();
  inline const ::google::protobuf::RepeatedPtrField< ::Item >&
      item_list() const;
  inline ::google::protobuf::RepeatedPtrField< ::Item >*
      mutable_item_list();

  // @@protoc_insertion_point(class_scope:ItemList)
 private:

  ::google::protobuf::RepeatedPtrField< ::Item > item_list_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(1 + 31) / 32];

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  friend void  protobuf_AddDesc_Item_2eproto_impl();
  #else
  friend void  protobuf_AddDesc_Item_2eproto();
  #endif
  friend void protobuf_AssignDesc_Item_2eproto();
  friend void protobuf_ShutdownFile_Item_2eproto();

  void InitAsDefaultInstance();
  static ItemList* default_instance_;
};
// -------------------------------------------------------------------

class GeneralGoods : public ::google::protobuf::MessageLite {
 public:
  GeneralGoods();
  virtual ~GeneralGoods();

  GeneralGoods(const GeneralGoods& from);

  inline GeneralGoods& operator=(const GeneralGoods& from) {
    CopyFrom(from);
    return *this;
  }

  static const GeneralGoods& default_instance();

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  // Returns the internal default instance pointer. This function can
  // return NULL thus should not be used by the user. This is intended
  // for Protobuf internal code. Please use default_instance() declared
  // above instead.
  static inline const GeneralGoods* internal_default_instance() {
    return default_instance_;
  }
  #endif

  void Swap(GeneralGoods* other);

  // implements Message ----------------------------------------------

  GeneralGoods* New() const;
  void CheckTypeAndMergeFrom(const ::google::protobuf::MessageLite& from);
  void CopyFrom(const GeneralGoods& from);
  void MergeFrom(const GeneralGoods& from);
  void Clear();
  bool IsInitialized() const;

  int ByteSize() const;
  bool MergePartialFromCodedStream(
      ::google::protobuf::io::CodedInputStream* input);
  void SerializeWithCachedSizes(
      ::google::protobuf::io::CodedOutputStream* output) const;
  int GetCachedSize() const { return _cached_size_; }
  private:
  void SharedCtor();
  void SharedDtor();
  void SetCachedSize(int size) const;
  public:

  ::std::string GetTypeName() const;

  // nested types ----------------------------------------------------

  // accessors -------------------------------------------------------

  // optional .Item item = 1;
  inline bool has_item() const;
  inline void clear_item();
  static const int kItemFieldNumber = 1;
  inline const ::Item& item() const;
  inline ::Item* mutable_item();
  inline ::Item* release_item();
  inline void set_allocated_item(::Item* item);

  // optional int32 cost = 2;
  inline bool has_cost() const;
  inline void clear_cost();
  static const int kCostFieldNumber = 2;
  inline ::google::protobuf::int32 cost() const;
  inline void set_cost(::google::protobuf::int32 value);

  // @@protoc_insertion_point(class_scope:GeneralGoods)
 private:
  inline void set_has_item();
  inline void clear_has_item();
  inline void set_has_cost();
  inline void clear_has_cost();

  ::Item* item_;
  ::google::protobuf::int32 cost_;

  mutable int _cached_size_;
  ::google::protobuf::uint32 _has_bits_[(2 + 31) / 32];

  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  friend void  protobuf_AddDesc_Item_2eproto_impl();
  #else
  friend void  protobuf_AddDesc_Item_2eproto();
  #endif
  friend void protobuf_AssignDesc_Item_2eproto();
  friend void protobuf_ShutdownFile_Item_2eproto();

  void InitAsDefaultInstance();
  static GeneralGoods* default_instance_;
};
// ===================================================================


// ===================================================================

// Pair

// required int32 key = 1;
inline bool Pair::has_key() const {
  return (_has_bits_[0] & 0x00000001u) != 0;
}
inline void Pair::set_has_key() {
  _has_bits_[0] |= 0x00000001u;
}
inline void Pair::clear_has_key() {
  _has_bits_[0] &= ~0x00000001u;
}
inline void Pair::clear_key() {
  key_ = 0;
  clear_has_key();
}
inline ::google::protobuf::int32 Pair::key() const {
  return key_;
}
inline void Pair::set_key(::google::protobuf::int32 value) {
  set_has_key();
  key_ = value;
}

// required int32 value = 2;
inline bool Pair::has_value() const {
  return (_has_bits_[0] & 0x00000002u) != 0;
}
inline void Pair::set_has_value() {
  _has_bits_[0] |= 0x00000002u;
}
inline void Pair::clear_has_value() {
  _has_bits_[0] &= ~0x00000002u;
}
inline void Pair::clear_value() {
  value_ = 0;
  clear_has_value();
}
inline ::google::protobuf::int32 Pair::value() const {
  return value_;
}
inline void Pair::set_value(::google::protobuf::int32 value) {
  set_has_value();
  value_ = value;
}

// -------------------------------------------------------------------

// Item

// required int32 id = 1;
inline bool Item::has_id() const {
  return (_has_bits_[0] & 0x00000001u) != 0;
}
inline void Item::set_has_id() {
  _has_bits_[0] |= 0x00000001u;
}
inline void Item::clear_has_id() {
  _has_bits_[0] &= ~0x00000001u;
}
inline void Item::clear_id() {
  id_ = 0;
  clear_has_id();
}
inline ::google::protobuf::int32 Item::id() const {
  return id_;
}
inline void Item::set_id(::google::protobuf::int32 value) {
  set_has_id();
  id_ = value;
}

// required int32 num = 2;
inline bool Item::has_num() const {
  return (_has_bits_[0] & 0x00000002u) != 0;
}
inline void Item::set_has_num() {
  _has_bits_[0] |= 0x00000002u;
}
inline void Item::clear_has_num() {
  _has_bits_[0] &= ~0x00000002u;
}
inline void Item::clear_num() {
  num_ = 0;
  clear_has_num();
}
inline ::google::protobuf::int32 Item::num() const {
  return num_;
}
inline void Item::set_num(::google::protobuf::int32 value) {
  set_has_num();
  num_ = value;
}

// required int32 guid = 3;
inline bool Item::has_guid() const {
  return (_has_bits_[0] & 0x00000004u) != 0;
}
inline void Item::set_has_guid() {
  _has_bits_[0] |= 0x00000004u;
}
inline void Item::clear_has_guid() {
  _has_bits_[0] &= ~0x00000004u;
}
inline void Item::clear_guid() {
  guid_ = 0;
  clear_has_guid();
}
inline ::google::protobuf::int32 Item::guid() const {
  return guid_;
}
inline void Item::set_guid(::google::protobuf::int32 value) {
  set_has_guid();
  guid_ = value;
}

// -------------------------------------------------------------------

// ItemList

// repeated .Item item_list = 1;
inline int ItemList::item_list_size() const {
  return item_list_.size();
}
inline void ItemList::clear_item_list() {
  item_list_.Clear();
}
inline const ::Item& ItemList::item_list(int index) const {
  return item_list_.Get(index);
}
inline ::Item* ItemList::mutable_item_list(int index) {
  return item_list_.Mutable(index);
}
inline ::Item* ItemList::add_item_list() {
  return item_list_.Add();
}
inline const ::google::protobuf::RepeatedPtrField< ::Item >&
ItemList::item_list() const {
  return item_list_;
}
inline ::google::protobuf::RepeatedPtrField< ::Item >*
ItemList::mutable_item_list() {
  return &item_list_;
}

// -------------------------------------------------------------------

// GeneralGoods

// optional .Item item = 1;
inline bool GeneralGoods::has_item() const {
  return (_has_bits_[0] & 0x00000001u) != 0;
}
inline void GeneralGoods::set_has_item() {
  _has_bits_[0] |= 0x00000001u;
}
inline void GeneralGoods::clear_has_item() {
  _has_bits_[0] &= ~0x00000001u;
}
inline void GeneralGoods::clear_item() {
  if (item_ != NULL) item_->::Item::Clear();
  clear_has_item();
}
inline const ::Item& GeneralGoods::item() const {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  return item_ != NULL ? *item_ : *default_instance().item_;
#else
  return item_ != NULL ? *item_ : *default_instance_->item_;
#endif
}
inline ::Item* GeneralGoods::mutable_item() {
  set_has_item();
  if (item_ == NULL) item_ = new ::Item;
  return item_;
}
inline ::Item* GeneralGoods::release_item() {
  clear_has_item();
  ::Item* temp = item_;
  item_ = NULL;
  return temp;
}
inline void GeneralGoods::set_allocated_item(::Item* item) {
  delete item_;
  item_ = item;
  if (item) {
    set_has_item();
  } else {
    clear_has_item();
  }
}

// optional int32 cost = 2;
inline bool GeneralGoods::has_cost() const {
  return (_has_bits_[0] & 0x00000002u) != 0;
}
inline void GeneralGoods::set_has_cost() {
  _has_bits_[0] |= 0x00000002u;
}
inline void GeneralGoods::clear_has_cost() {
  _has_bits_[0] &= ~0x00000002u;
}
inline void GeneralGoods::clear_cost() {
  cost_ = 0;
  clear_has_cost();
}
inline ::google::protobuf::int32 GeneralGoods::cost() const {
  return cost_;
}
inline void GeneralGoods::set_cost(::google::protobuf::int32 value) {
  set_has_cost();
  cost_ = value;
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)

#endif  // PROTOBUF_Item_2eproto__INCLUDED
