//
//  MatrixView.h
//  StarClient
//
//  Created by hankai on 16/4/28.
//
//

#ifndef MatrixView_h
#define MatrixView_h

#include "cocos2d.h"
#include "ui/CocosGUI.h"

USING_NS_CC;

class MatrixView : public ui::ScrollView {
public:
    MatrixView(int rowCount,int colCount);
    
    static MatrixView* create(int rowCount,int colCount);
    
    virtual bool init()override;
    
    void setRowCol(int rowCount,int colCount);
    
    //override methods
    virtual void doLayout() override;
    virtual void requestDoLayout() override;
    virtual void addChild(Node* child)override;
    virtual void addChild(Node* child, int zOrder, const std::string &name) override;
    
    void pushBackCustomItem(Widget* item);
    void removeCustomItem(Node* item);
protected:
    
    void updateInnerContainerSize();
    void updateItemsPosition();
    
    
    virtual void onItemListChanged();
    
    int _rowCount,_colCount;
    
    Vector<Widget *> _items;
    
    float _itemsMargin;
    
    bool _innerContainerDoLayoutDirty;
};

#endif /* MatrixView_h */
