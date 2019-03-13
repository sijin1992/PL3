//
//  MatrixView.cpp
//  StarClient
//
//  Created by hankai on 16/4/28.
//
//

#include "MatrixView.h"

MatrixView::MatrixView(int rowCount,int colCount)
:_innerContainerDoLayoutDirty(false)
,_itemsMargin(2){
    _rowCount = rowCount;
    _colCount = colCount;
}

MatrixView* MatrixView::create(int rowCount,int colCount){
    MatrixView* widget = new (std::nothrow) MatrixView(rowCount,colCount);
    if (widget && widget->init())
    {
        widget->autorelease();
        return widget;
    }
    CC_SAFE_DELETE(widget);
    return nullptr;
}

bool MatrixView::init()
{
    if (ScrollView::init())
    {
        setDirection(Direction::VERTICAL);
        return true;
    }
    return false;
}

void MatrixView::setRowCol(int rowCount,int colCount){
    _rowCount = rowCount;
    _colCount = colCount;
    requestDoLayout();
}

void MatrixView::onItemListChanged(){
    _outOfBoundaryAmountDirty = true;
}

void MatrixView::doLayout(){
    
    if(!_innerContainerDoLayoutDirty){
        return;
    }
    
    updateItemsPosition();
    
    _innerContainer->forceDoLayout();
    _innerContainerDoLayoutDirty = false;
}
void MatrixView::requestDoLayout(){
    _innerContainerDoLayoutDirty = true;
}

void MatrixView::addChild(Node* child){
    MatrixView::addChild(child, child->getLocalZOrder(), child->getName());
}

void MatrixView::addChild(Node* child, int zOrder, const std::string &name)
{
    ScrollView::addChild(child, zOrder, name);
    
    Widget* widget = dynamic_cast<Widget*>(child);
    if (nullptr != widget)
    {
        _items.pushBack(widget);
        onItemListChanged();
    }
}

void MatrixView::updateItemsPosition(){
    updateInnerContainerSize();
    
    auto containerSize = getInnerContainerSize();
    auto itemSize = _items.front()->getContentSize();
    
    
    
    
    for (int i = 0; i<_items.size(); ++i) {
        int row = i / _colCount;
        int col = i % _colCount;
        
        auto x = _itemsMargin * (col + 1) + itemSize.width/2 + itemSize.width * col;
        auto y = containerSize.height - itemSize.height - itemSize.height * row - _itemsMargin * (row + 1);
        _items.at(i)->setPosition(Vec2(x,y));
    }
}

void MatrixView::updateInnerContainerSize(){
    if (_items.empty()) {
        return;
    }
    auto count = _items.size();
    int rowCount = _rowCount;
    int colCount = _colCount;
    
    if (colCount == 0) {
        rowCount = 1;
        colCount = _items.size();
    }else if(rowCount == 0){
        rowCount = count / colCount;
        if(count % colCount > 0){
            ++rowCount;
        }
    }
    
    
    //auto defaultSize = getInnerContainerSize();
    auto defaultSize = getContentSize();
    
    auto itemSize = _items.front()->getContentSize();
    
    auto size = Size((colCount) * itemSize.width + (colCount+1) * _itemsMargin, (rowCount) * itemSize.height + (rowCount+1) * _itemsMargin);
    
    if (size.width < defaultSize.width) {
        size.width = defaultSize.width;
    }
    if (size.height < defaultSize.height) {
        size.height = defaultSize.height;
    }
    
    
    setInnerContainerSize(size);
}

void MatrixView::pushBackCustomItem(Widget* item)
{
    addChild(item);
    requestDoLayout();
}

void MatrixView::removeCustomItem(Node* item){
    if(item == nullptr){
        return;
    }
    for (int i = 0; i < _items.size(); ++i) {
        if (item == _items.at(i)) {
            _items.at(i)->removeFromParent();
            _items.erase(i);
            requestDoLayout();
            break;
        }
    }
}