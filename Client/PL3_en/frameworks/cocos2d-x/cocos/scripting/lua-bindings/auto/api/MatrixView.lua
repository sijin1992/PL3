
--------------------------------
-- @module MatrixView
-- @extend ScrollView
-- @parent_module mc

--------------------------------
-- 
-- @function [parent=#MatrixView] doLayout 
-- @param self
-- @return MatrixView#MatrixView self (return value: MatrixView)
        
--------------------------------
-- 
-- @function [parent=#MatrixView] setRowCol 
-- @param self
-- @param #int rowCount
-- @param #int colCount
-- @return MatrixView#MatrixView self (return value: MatrixView)
        
--------------------------------
-- 
-- @function [parent=#MatrixView] removeCustomItem 
-- @param self
-- @param #cc.Node item
-- @return MatrixView#MatrixView self (return value: MatrixView)
        
--------------------------------
-- 
-- @function [parent=#MatrixView] pushBackCustomItem 
-- @param self
-- @param #ccui.Widget item
-- @return MatrixView#MatrixView self (return value: MatrixView)
        
--------------------------------
-- 
-- @function [parent=#MatrixView] create 
-- @param self
-- @param #int rowCount
-- @param #int colCount
-- @return MatrixView#MatrixView ret (return value: MatrixView)
        
--------------------------------
-- @overload self, cc.Node, int, string         
-- @overload self, cc.Node         
-- @function [parent=#MatrixView] addChild
-- @param self
-- @param #cc.Node child
-- @param #int zOrder
-- @param #string name
-- @return MatrixView#MatrixView self (return value: MatrixView)

--------------------------------
-- 
-- @function [parent=#MatrixView] init 
-- @param self
-- @return bool#bool ret (return value: bool)
        
--------------------------------
-- 
-- @function [parent=#MatrixView] requestDoLayout 
-- @param self
-- @return MatrixView#MatrixView self (return value: MatrixView)
        
--------------------------------
-- 
-- @function [parent=#MatrixView] MatrixView 
-- @param self
-- @param #int rowCount
-- @param #int colCount
-- @return MatrixView#MatrixView self (return value: MatrixView)
        
return nil
