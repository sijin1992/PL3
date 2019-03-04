// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: Equip.proto

#define INTERNAL_SUPPRESS_PROTOBUF_FIELD_DEPRECATION
#include "Equip.pb.h"

#include <algorithm>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/once.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/wire_format_lite_inl.h>
// @@protoc_insertion_point(includes)

void protobuf_ShutdownFile_Equip_2eproto() {
  delete Gem::default_instance_;
  delete Equip::default_instance_;
  delete ForgeEquip::default_instance_;
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
void protobuf_AddDesc_Equip_2eproto_impl() {
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#else
void protobuf_AddDesc_Equip_2eproto() {
  static bool already_here = false;
  if (already_here) return;
  already_here = true;
  GOOGLE_PROTOBUF_VERIFY_VERSION;

#endif
  Gem::default_instance_ = new Gem();
  Equip::default_instance_ = new Equip();
  ForgeEquip::default_instance_ = new ForgeEquip();
  Gem::default_instance_->InitAsDefaultInstance();
  Equip::default_instance_->InitAsDefaultInstance();
  ForgeEquip::default_instance_->InitAsDefaultInstance();
  ::google::protobuf::internal::OnShutdown(&protobuf_ShutdownFile_Equip_2eproto);
}

#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
GOOGLE_PROTOBUF_DECLARE_ONCE(protobuf_AddDesc_Equip_2eproto_once_);
void protobuf_AddDesc_Equip_2eproto() {
  ::google::protobuf::::google::protobuf::GoogleOnceInit(&protobuf_AddDesc_Equip_2eproto_once_,
                 &protobuf_AddDesc_Equip_2eproto_impl);
}
#else
// Force AddDescriptors() to be called at static initialization time.
struct StaticDescriptorInitializer_Equip_2eproto {
  StaticDescriptorInitializer_Equip_2eproto() {
    protobuf_AddDesc_Equip_2eproto();
  }
} static_descriptor_initializer_Equip_2eproto_;
#endif

// ===================================================================

#ifndef _MSC_VER
const int Gem::kIdFieldNumber;
const int Gem::kNumFieldNumber;
#endif  // !_MSC_VER

Gem::Gem()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void Gem::InitAsDefaultInstance() {
}

Gem::Gem(const Gem& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void Gem::SharedCtor() {
  _cached_size_ = 0;
  id_ = 0;
  num_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

Gem::~Gem() {
  SharedDtor();
}

void Gem::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
  }
}

void Gem::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const Gem& Gem::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Equip_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Equip_2eproto();
#endif
  return *default_instance_;
}

Gem* Gem::default_instance_ = NULL;

Gem* Gem::New() const {
  return new Gem;
}

void Gem::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    id_ = 0;
    num_ = 0;
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool Gem::MergePartialFromCodedStream(
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

void Gem::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 id = 1;
  if (has_id()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->id(), output);
  }

  // required int32 num = 2;
  if (has_num()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->num(), output);
  }

}

int Gem::ByteSize() const {
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

  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void Gem::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const Gem*>(&from));
}

void Gem::MergeFrom(const Gem& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_id()) {
      set_id(from.id());
    }
    if (from.has_num()) {
      set_num(from.num());
    }
  }
}

void Gem::CopyFrom(const Gem& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool Gem::IsInitialized() const {
  if ((_has_bits_[0] & 0x00000003) != 0x00000003) return false;

  return true;
}

void Gem::Swap(Gem* other) {
  if (other != this) {
    std::swap(id_, other->id_);
    std::swap(num_, other->num_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string Gem::GetTypeName() const {
  return "Gem";
}


// ===================================================================

#ifndef _MSC_VER
const int Equip::kGuidFieldNumber;
const int Equip::kEquipIdFieldNumber;
const int Equip::kShipIdFieldNumber;
const int Equip::kTypeFieldNumber;
const int Equip::kQualityFieldNumber;
const int Equip::kStatusFieldNumber;
const int Equip::kLevelFieldNumber;
const int Equip::kStrengthFieldNumber;
const int Equip::kAttributesBaseFieldNumber;
#endif  // !_MSC_VER

Equip::Equip()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void Equip::InitAsDefaultInstance() {
}

Equip::Equip(const Equip& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void Equip::SharedCtor() {
  _cached_size_ = 0;
  guid_ = 0;
  equip_id_ = 0;
  ship_id_ = 0;
  type_ = 0;
  quality_ = 0;
  status_ = 0;
  level_ = 0;
  strength_ = 0;
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

Equip::~Equip() {
  SharedDtor();
}

void Equip::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
  }
}

void Equip::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const Equip& Equip::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Equip_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Equip_2eproto();
#endif
  return *default_instance_;
}

Equip* Equip::default_instance_ = NULL;

Equip* Equip::New() const {
  return new Equip;
}

void Equip::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    guid_ = 0;
    equip_id_ = 0;
    ship_id_ = 0;
    type_ = 0;
    quality_ = 0;
    status_ = 0;
    level_ = 0;
    strength_ = 0;
  }
  attributes_base_.Clear();
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool Equip::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // required int32 guid = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &guid_)));
          set_has_guid();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(16)) goto parse_equip_id;
        break;
      }

      // required int32 equip_id = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_equip_id:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &equip_id_)));
          set_has_equip_id();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(24)) goto parse_ship_id;
        break;
      }

      // required int32 ship_id = 3;
      case 3: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_ship_id:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &ship_id_)));
          set_has_ship_id();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(32)) goto parse_type;
        break;
      }

      // required int32 type = 4;
      case 4: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_type:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &type_)));
          set_has_type();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(40)) goto parse_quality;
        break;
      }

      // required int32 quality = 5;
      case 5: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_quality:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &quality_)));
          set_has_quality();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(48)) goto parse_status;
        break;
      }

      // required int32 status = 6;
      case 6: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_status:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &status_)));
          set_has_status();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(56)) goto parse_level;
        break;
      }

      // required int32 level = 7;
      case 7: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_level:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &level_)));
          set_has_level();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(64)) goto parse_strength;
        break;
      }

      // required int32 strength = 8;
      case 8: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_strength:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &strength_)));
          set_has_strength();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(72)) goto parse_attributes_base;
        break;
      }

      // repeated int32 attributes_base = 9;
      case 9: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_attributes_base:
          DO_((::google::protobuf::internal::WireFormatLite::ReadRepeatedPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 1, 72, input, this->mutable_attributes_base())));
        } else if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag)
                   == ::google::protobuf::internal::WireFormatLite::
                      WIRETYPE_LENGTH_DELIMITED) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPackedPrimitiveNoInline<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, this->mutable_attributes_base())));
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(72)) goto parse_attributes_base;
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

void Equip::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 guid = 1;
  if (has_guid()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->guid(), output);
  }

  // required int32 equip_id = 2;
  if (has_equip_id()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->equip_id(), output);
  }

  // required int32 ship_id = 3;
  if (has_ship_id()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(3, this->ship_id(), output);
  }

  // required int32 type = 4;
  if (has_type()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(4, this->type(), output);
  }

  // required int32 quality = 5;
  if (has_quality()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(5, this->quality(), output);
  }

  // required int32 status = 6;
  if (has_status()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(6, this->status(), output);
  }

  // required int32 level = 7;
  if (has_level()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(7, this->level(), output);
  }

  // required int32 strength = 8;
  if (has_strength()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(8, this->strength(), output);
  }

  // repeated int32 attributes_base = 9;
  for (int i = 0; i < this->attributes_base_size(); i++) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(
      9, this->attributes_base(i), output);
  }

}

int Equip::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // required int32 guid = 1;
    if (has_guid()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->guid());
    }

    // required int32 equip_id = 2;
    if (has_equip_id()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->equip_id());
    }

    // required int32 ship_id = 3;
    if (has_ship_id()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->ship_id());
    }

    // required int32 type = 4;
    if (has_type()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->type());
    }

    // required int32 quality = 5;
    if (has_quality()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->quality());
    }

    // required int32 status = 6;
    if (has_status()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->status());
    }

    // required int32 level = 7;
    if (has_level()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->level());
    }

    // required int32 strength = 8;
    if (has_strength()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->strength());
    }

  }
  // repeated int32 attributes_base = 9;
  {
    int data_size = 0;
    for (int i = 0; i < this->attributes_base_size(); i++) {
      data_size += ::google::protobuf::internal::WireFormatLite::
        Int32Size(this->attributes_base(i));
    }
    total_size += 1 * this->attributes_base_size() + data_size;
  }

  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void Equip::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const Equip*>(&from));
}

void Equip::MergeFrom(const Equip& from) {
  GOOGLE_CHECK_NE(&from, this);
  attributes_base_.MergeFrom(from.attributes_base_);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_guid()) {
      set_guid(from.guid());
    }
    if (from.has_equip_id()) {
      set_equip_id(from.equip_id());
    }
    if (from.has_ship_id()) {
      set_ship_id(from.ship_id());
    }
    if (from.has_type()) {
      set_type(from.type());
    }
    if (from.has_quality()) {
      set_quality(from.quality());
    }
    if (from.has_status()) {
      set_status(from.status());
    }
    if (from.has_level()) {
      set_level(from.level());
    }
    if (from.has_strength()) {
      set_strength(from.strength());
    }
  }
}

void Equip::CopyFrom(const Equip& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool Equip::IsInitialized() const {
  if ((_has_bits_[0] & 0x000000ff) != 0x000000ff) return false;

  return true;
}

void Equip::Swap(Equip* other) {
  if (other != this) {
    std::swap(guid_, other->guid_);
    std::swap(equip_id_, other->equip_id_);
    std::swap(ship_id_, other->ship_id_);
    std::swap(type_, other->type_);
    std::swap(quality_, other->quality_);
    std::swap(status_, other->status_);
    std::swap(level_, other->level_);
    std::swap(strength_, other->strength_);
    attributes_base_.Swap(&other->attributes_base_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string Equip::GetTypeName() const {
  return "Equip";
}


// ===================================================================

#ifndef _MSC_VER
const int ForgeEquip::kGuidFieldNumber;
const int ForgeEquip::kEquipIdFieldNumber;
const int ForgeEquip::kStartTimeFieldNumber;
#endif  // !_MSC_VER

ForgeEquip::ForgeEquip()
  : ::google::protobuf::MessageLite() {
  SharedCtor();
}

void ForgeEquip::InitAsDefaultInstance() {
}

ForgeEquip::ForgeEquip(const ForgeEquip& from)
  : ::google::protobuf::MessageLite() {
  SharedCtor();
  MergeFrom(from);
}

void ForgeEquip::SharedCtor() {
  _cached_size_ = 0;
  guid_ = 0;
  equip_id_ = 0;
  start_time_ = GOOGLE_LONGLONG(0);
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

ForgeEquip::~ForgeEquip() {
  SharedDtor();
}

void ForgeEquip::SharedDtor() {
  #ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  if (this != &default_instance()) {
  #else
  if (this != default_instance_) {
  #endif
  }
}

void ForgeEquip::SetCachedSize(int size) const {
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
}
const ForgeEquip& ForgeEquip::default_instance() {
#ifdef GOOGLE_PROTOBUF_NO_STATIC_INITIALIZER
  protobuf_AddDesc_Equip_2eproto();
#else
  if (default_instance_ == NULL) protobuf_AddDesc_Equip_2eproto();
#endif
  return *default_instance_;
}

ForgeEquip* ForgeEquip::default_instance_ = NULL;

ForgeEquip* ForgeEquip::New() const {
  return new ForgeEquip;
}

void ForgeEquip::Clear() {
  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    guid_ = 0;
    equip_id_ = 0;
    start_time_ = GOOGLE_LONGLONG(0);
  }
  ::memset(_has_bits_, 0, sizeof(_has_bits_));
}

bool ForgeEquip::MergePartialFromCodedStream(
    ::google::protobuf::io::CodedInputStream* input) {
#define DO_(EXPRESSION) if (!(EXPRESSION)) return false
  ::google::protobuf::uint32 tag;
  while ((tag = input->ReadTag()) != 0) {
    switch (::google::protobuf::internal::WireFormatLite::GetTagFieldNumber(tag)) {
      // required int32 guid = 1;
      case 1: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &guid_)));
          set_has_guid();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(16)) goto parse_equip_id;
        break;
      }

      // required int32 equip_id = 2;
      case 2: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_equip_id:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int32, ::google::protobuf::internal::WireFormatLite::TYPE_INT32>(
                 input, &equip_id_)));
          set_has_equip_id();
        } else {
          goto handle_uninterpreted;
        }
        if (input->ExpectTag(24)) goto parse_start_time;
        break;
      }

      // required int64 start_time = 3;
      case 3: {
        if (::google::protobuf::internal::WireFormatLite::GetTagWireType(tag) ==
            ::google::protobuf::internal::WireFormatLite::WIRETYPE_VARINT) {
         parse_start_time:
          DO_((::google::protobuf::internal::WireFormatLite::ReadPrimitive<
                   ::google::protobuf::int64, ::google::protobuf::internal::WireFormatLite::TYPE_INT64>(
                 input, &start_time_)));
          set_has_start_time();
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

void ForgeEquip::SerializeWithCachedSizes(
    ::google::protobuf::io::CodedOutputStream* output) const {
  // required int32 guid = 1;
  if (has_guid()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(1, this->guid(), output);
  }

  // required int32 equip_id = 2;
  if (has_equip_id()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt32(2, this->equip_id(), output);
  }

  // required int64 start_time = 3;
  if (has_start_time()) {
    ::google::protobuf::internal::WireFormatLite::WriteInt64(3, this->start_time(), output);
  }

}

int ForgeEquip::ByteSize() const {
  int total_size = 0;

  if (_has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    // required int32 guid = 1;
    if (has_guid()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->guid());
    }

    // required int32 equip_id = 2;
    if (has_equip_id()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int32Size(
          this->equip_id());
    }

    // required int64 start_time = 3;
    if (has_start_time()) {
      total_size += 1 +
        ::google::protobuf::internal::WireFormatLite::Int64Size(
          this->start_time());
    }

  }
  GOOGLE_SAFE_CONCURRENT_WRITES_BEGIN();
  _cached_size_ = total_size;
  GOOGLE_SAFE_CONCURRENT_WRITES_END();
  return total_size;
}

void ForgeEquip::CheckTypeAndMergeFrom(
    const ::google::protobuf::MessageLite& from) {
  MergeFrom(*::google::protobuf::down_cast<const ForgeEquip*>(&from));
}

void ForgeEquip::MergeFrom(const ForgeEquip& from) {
  GOOGLE_CHECK_NE(&from, this);
  if (from._has_bits_[0 / 32] & (0xffu << (0 % 32))) {
    if (from.has_guid()) {
      set_guid(from.guid());
    }
    if (from.has_equip_id()) {
      set_equip_id(from.equip_id());
    }
    if (from.has_start_time()) {
      set_start_time(from.start_time());
    }
  }
}

void ForgeEquip::CopyFrom(const ForgeEquip& from) {
  if (&from == this) return;
  Clear();
  MergeFrom(from);
}

bool ForgeEquip::IsInitialized() const {
  if ((_has_bits_[0] & 0x00000007) != 0x00000007) return false;

  return true;
}

void ForgeEquip::Swap(ForgeEquip* other) {
  if (other != this) {
    std::swap(guid_, other->guid_);
    std::swap(equip_id_, other->equip_id_);
    std::swap(start_time_, other->start_time_);
    std::swap(_has_bits_[0], other->_has_bits_[0]);
    std::swap(_cached_size_, other->_cached_size_);
  }
}

::std::string ForgeEquip::GetTypeName() const {
  return "ForgeEquip";
}


// @@protoc_insertion_point(namespace_scope)

// @@protoc_insertion_point(global_scope)
