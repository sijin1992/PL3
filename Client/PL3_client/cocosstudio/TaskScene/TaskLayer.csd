<GameFile>
  <PropertyGroup Name="TaskLayer" Type="Layer" ID="8adf5425-25b9-44a6-8e7f-ca1cade2b204" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="50" Speed="1.0000">
        <Timeline ActionTag="961944226" Property="Scale">
          <ScaleFrame FrameIndex="0" X="0.0100" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="15" X="1.1000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="35" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="961944226" Property="Alpha">
          <IntFrame FrameIndex="0" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="15" Value="229">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="35" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="595546724" Property="Scale">
          <ScaleFrame FrameIndex="33" X="0.0100" Y="0.0100">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="38" X="1.2000" Y="1.2000">
            <EasingData Type="0" />
          </ScaleFrame>
          <ScaleFrame FrameIndex="48" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="595546724" Property="Alpha">
          <IntFrame FrameIndex="33" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="38" Value="178">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="48" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="1692637724" Property="Alpha">
          <IntFrame FrameIndex="30" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="40" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="-1741698017" Property="Alpha">
          <IntFrame FrameIndex="33" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="42" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="-1999463409" Property="Alpha">
          <IntFrame FrameIndex="36" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="44" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="-1100449371" Property="Alpha">
          <IntFrame FrameIndex="40" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="50" Value="255">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="intro" StartIndex="0" EndIndex="50">
          <RenderColor A="255" R="0" G="206" B="209" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Layer" Tag="49" ctype="GameLayerObjectData">
        <Size X="1136.0000" Y="768.0000" />
        <Children>
          <AbstractNodeData Name="back" ActionTag="558729484" Alpha="175" Tag="166" IconVisible="False" LeftMargin="-2271.4717" RightMargin="-2270.4385" TopMargin="-995.7422" BottomMargin="-982.3779" TouchEnable="True" LeftEage="7" RightEage="7" TopEage="2" BottomEage="2" Scale9OriginX="7" Scale9OriginY="2" Scale9Width="10" Scale9Height="3" ctype="ImageViewObjectData">
            <Size X="5677.9102" Y="2746.1201" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="567.4834" Y="390.6821" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="26" G="26" B="26" />
            <PrePosition X="0.4995" Y="0.5087" />
            <PreSize X="4.9982" Y="3.5757" />
            <FileData Type="Normal" Path="ShipsScene/ui_bar_yellow_full.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="back_0" ActionTag="-905370997" Alpha="197" Tag="165" IconVisible="False" LeftMargin="-2271.4851" RightMargin="-2270.4250" TopMargin="-992.9199" BottomMargin="-985.2002" TouchEnable="True" Scale9Enable="True" LeftEage="7" RightEage="7" TopEage="2" BottomEage="2" Scale9OriginX="7" Scale9OriginY="2" Scale9Width="8" Scale9Height="276" ctype="ImageViewObjectData">
            <Size X="5677.9102" Y="2746.1201" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="567.4700" Y="387.8599" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.4995" Y="0.5050" />
            <PreSize X="4.9982" Y="3.5757" />
            <FileData Type="Normal" Path="ShopScene/ui/line_bt2.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="background" ActionTag="961944226" Alpha="0" Tag="164" IconVisible="False" LeftMargin="0.9137" RightMargin="1.0863" TopMargin="96.8187" BottomMargin="110.1813" ctype="SpriteObjectData">
            <Size X="1134.0000" Y="561.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="567.9137" Y="390.6813" />
            <Scale ScaleX="0.0100" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.4999" Y="0.5087" />
            <PreSize X="0.9982" Y="0.7305" />
            <FileData Type="Normal" Path="Common/newUI/common_bj.png" Plist="" />
            <BlendFunc Src="1" Dst="771" />
          </AbstractNodeData>
          <AbstractNodeData Name="close" ActionTag="595546724" Alpha="0" Tag="159" IconVisible="False" LeftMargin="1000.6577" RightMargin="83.3423" TopMargin="108.6066" BottomMargin="607.3934" TouchEnable="True" FontSize="14" LeftEage="15" RightEage="15" TopEage="11" BottomEage="11" Scale9OriginX="15" Scale9OriginY="11" Scale9Width="22" Scale9Height="30" ShadowOffsetX="2.0000" ShadowOffsetY="-2.0000" ctype="ButtonObjectData">
            <Size X="52.0000" Y="52.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="1026.6577" Y="633.3934" />
            <Scale ScaleX="0.0100" ScaleY="0.0100" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.9037" Y="0.8247" />
            <PreSize X="0.0458" Y="0.0677" />
            <TextColor A="255" R="65" G="65" B="70" />
            <DisabledFileData Type="Default" Path="Default/Button_Disable.png" Plist="" />
            <PressedFileData Type="Normal" Path="Common/newUI/button_close_light.png" Plist="" />
            <NormalFileData Type="Normal" Path="Common/newUI/button_close.png" Plist="" />
            <OutlineColor A="255" R="255" G="0" B="0" />
            <ShadowColor A="255" R="110" G="110" B="110" />
          </AbstractNodeData>
          <AbstractNodeData Name="title" ActionTag="686826451" Tag="160" IconVisible="False" LeftMargin="534.8260" RightMargin="535.1740" TopMargin="119.4144" BottomMargin="617.5856" LeftEage="21" RightEage="21" TopEage="10" BottomEage="10" Scale9OriginX="21" Scale9OriginY="10" Scale9Width="24" Scale9Height="11" ctype="ImageViewObjectData">
            <Size X="66.0000" Y="31.0000" />
            <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
            <Position X="567.8260" Y="633.0856" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.4998" Y="0.8243" />
            <PreSize X="0.0581" Y="0.0404" />
            <FileData Type="Normal" Path="TaskScene/ui/Task.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="leftBg" ActionTag="-1975515991" Tag="110" IconVisible="False" LeftMargin="113.6900" RightMargin="843.3100" TopMargin="168.4301" BottomMargin="139.5699" Scale9Enable="True" LeftEage="3" RightEage="3" TopEage="154" BottomEage="154" Scale9OriginX="3" Scale9OriginY="154" Scale9Width="4" Scale9Height="161" ctype="ImageViewObjectData">
            <Size X="179.0000" Y="460.0000" />
            <Children>
              <AbstractNodeData Name="mode_1" ActionTag="1692637724" Alpha="0" Tag="1" IconVisible="True" LeftMargin="85.8429" RightMargin="93.1571" TopMargin="38.1432" BottomMargin="421.8568" ctype="SingleNodeObjectData">
                <Size X="0.0000" Y="0.0000" />
                <Children>
                  <AbstractNodeData Name="selected" ActionTag="210814924" VisibleForFrame="False" Tag="112" IconVisible="False" LeftMargin="-86.8028" RightMargin="-100.1972" TopMargin="-34.5256" BottomMargin="-29.4744" TouchEnable="True" LeftEage="102" RightEage="102" TopEage="22" BottomEage="22" Scale9OriginX="102" Scale9OriginY="22" Scale9Width="4" Scale9Height="18" ctype="ImageViewObjectData">
                    <Size X="187.0000" Y="64.0000" />
                    <AnchorPoint ScaleX="1.0000" ScaleY="1.0000" />
                    <Position X="100.1972" Y="34.5256" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/yq_z_light.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="point" ActionTag="1825171232" VisibleForFrame="False" Tag="115" IconVisible="False" LeftMargin="76.2627" RightMargin="-94.2627" TopMargin="-37.5918" BottomMargin="19.5918" ctype="SpriteObjectData">
                    <Size X="18.0000" Y="18.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="85.2627" Y="28.5918" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/ui/spherical_red.png" Plist="" />
                    <BlendFunc Src="1" Dst="771" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="normal" ActionTag="-98669830" Alpha="0" Tag="113" IconVisible="False" LeftMargin="-83.0000" RightMargin="-77.0000" TopMargin="-35.0000" BottomMargin="-29.0000" TouchEnable="True" LeftEage="102" RightEage="102" TopEage="22" BottomEage="22" Scale9OriginX="102" Scale9OriginY="22" Scale9Width="4" Scale9Height="18" ctype="ImageViewObjectData">
                    <Size X="160.0000" Y="64.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="-3.0000" Y="3.0000" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/yq_z_light.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="text" ActionTag="204549755" Tag="114" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="-21.5000" RightMargin="-21.5000" TopMargin="-17.5000" BottomMargin="-17.5000" FontSize="23" LabelText="Hot" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
                    <Size X="43.0000" Y="35.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="86" G="108" B="119" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                    <OutlineColor A="255" R="255" G="0" B="0" />
                    <ShadowColor A="255" R="66" G="100" B="138" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="line" ActionTag="345085992" Tag="116" RotationSkewX="90.0000" RotationSkewY="90.0000" IconVisible="False" LeftMargin="-21.9499" RightMargin="20.9499" TopMargin="-19.8437" BottomMargin="-127.1563" FlipY="True" Scale9Enable="True" TopEage="14" BottomEage="20" Scale9OriginY="14" Scale9Width="1" Scale9Height="15" ctype="ImageViewObjectData">
                    <Size X="1.0000" Y="147.0000" />
                    <AnchorPoint ScaleX="0.6099" ScaleY="0.6532" />
                    <Position X="-21.3400" Y="-31.1359" />
                    <Scale ScaleX="1.0000" ScaleY="1.1131" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/line_fg01.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="text_0" ActionTag="-1988589763" VisibleForFrame="False" Tag="117" IconVisible="False" LeftMargin="-10.5000" RightMargin="-34.5000" TopMargin="-17.9998" BottomMargin="-18.0002" FontSize="24" LabelText="Hot" ShadowOffsetX="1.5000" ShadowOffsetY="-2.5000" ctype="TextObjectData">
                    <Size X="45.0000" Y="36.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="12.0000" Y="-0.0002" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="254" G="255" B="254" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                    <OutlineColor A="255" R="77" G="77" B="77" />
                    <ShadowColor A="255" R="26" G="57" B="101" />
                  </AbstractNodeData>
                </Children>
                <AnchorPoint />
                <Position X="85.8429" Y="421.8568" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.4796" Y="0.9171" />
                <PreSize X="0.0000" Y="0.0000" />
              </AbstractNodeData>
              <AbstractNodeData Name="mode_2" ActionTag="-1741698017" Alpha="0" Tag="2" IconVisible="True" LeftMargin="85.8429" RightMargin="93.1571" TopMargin="105.8714" BottomMargin="354.1286" ctype="SingleNodeObjectData">
                <Size X="0.0000" Y="0.0000" />
                <Children>
                  <AbstractNodeData Name="selected" ActionTag="958584669" Tag="119" IconVisible="False" LeftMargin="-86.8028" RightMargin="-100.1972" TopMargin="-34.5261" BottomMargin="-29.4739" TouchEnable="True" LeftEage="102" RightEage="102" TopEage="22" BottomEage="22" Scale9OriginX="102" Scale9OriginY="22" Scale9Width="4" Scale9Height="18" ctype="ImageViewObjectData">
                    <Size X="187.0000" Y="64.0000" />
                    <AnchorPoint ScaleX="1.0000" ScaleY="1.0000" />
                    <Position X="100.1972" Y="34.5261" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/yq_z_light.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="point" ActionTag="-1537137682" VisibleForFrame="False" Tag="122" IconVisible="False" LeftMargin="76.1867" RightMargin="-94.1867" TopMargin="-34.0619" BottomMargin="16.0619" ctype="SpriteObjectData">
                    <Size X="18.0000" Y="18.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="85.1867" Y="25.0619" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/ui/spherical_red.png" Plist="" />
                    <BlendFunc Src="1" Dst="771" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="normal" ActionTag="-817488889" Alpha="0" Tag="120" IconVisible="False" LeftMargin="-83.0000" RightMargin="-77.0000" TopMargin="-35.0000" BottomMargin="-29.0000" TouchEnable="True" LeftEage="102" RightEage="102" TopEage="22" BottomEage="22" Scale9OriginX="102" Scale9OriginY="22" Scale9Width="4" Scale9Height="18" ctype="ImageViewObjectData">
                    <Size X="160.0000" Y="64.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="-3.0000" Y="3.0000" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/yq_z_light.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="text" ActionTag="751325446" Tag="121" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="-21.0000" RightMargin="-21.0000" TopMargin="-17.5000" BottomMargin="-17.5000" FontSize="23" LabelText="Res" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
                    <Size X="42.0000" Y="35.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="86" G="108" B="119" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                    <OutlineColor A="255" R="255" G="0" B="0" />
                    <ShadowColor A="255" R="66" G="100" B="138" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="line" ActionTag="1725254469" Tag="123" RotationSkewX="90.0000" RotationSkewY="90.0000" IconVisible="False" LeftMargin="-21.9519" RightMargin="20.9519" TopMargin="-19.8435" BottomMargin="-127.1565" FlipY="True" Scale9Enable="True" TopEage="14" BottomEage="20" Scale9OriginY="14" Scale9Width="1" Scale9Height="15" ctype="ImageViewObjectData">
                    <Size X="1.0000" Y="147.0000" />
                    <AnchorPoint ScaleX="0.6099" ScaleY="0.6532" />
                    <Position X="-21.3420" Y="-31.1361" />
                    <Scale ScaleX="1.0000" ScaleY="1.1131" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/line_fg01.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="text_0" ActionTag="-1339598555" VisibleForFrame="False" Tag="124" IconVisible="False" LeftMargin="-10.0000" RightMargin="-34.0000" TopMargin="-18.0000" BottomMargin="-18.0000" FontSize="24" LabelText="Res" ShadowOffsetX="1.5000" ShadowOffsetY="-2.5000" ctype="TextObjectData">
                    <Size X="44.0000" Y="36.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="12.0000" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="254" G="255" B="254" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                    <OutlineColor A="255" R="77" G="77" B="77" />
                    <ShadowColor A="255" R="26" G="57" B="101" />
                  </AbstractNodeData>
                </Children>
                <AnchorPoint />
                <Position X="85.8429" Y="354.1286" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.4796" Y="0.7698" />
                <PreSize X="0.0000" Y="0.0000" />
              </AbstractNodeData>
              <AbstractNodeData Name="mode_3" ActionTag="-1999463409" Alpha="0" Tag="3" IconVisible="True" LeftMargin="85.8429" RightMargin="93.1571" TopMargin="173.5991" BottomMargin="286.4009" ctype="SingleNodeObjectData">
                <Size X="0.0000" Y="0.0000" />
                <Children>
                  <AbstractNodeData Name="selected" ActionTag="1802590886" VisibleForFrame="False" Tag="126" IconVisible="False" LeftMargin="-86.8028" RightMargin="-100.1972" TopMargin="-34.5261" BottomMargin="-29.4739" TouchEnable="True" LeftEage="102" RightEage="102" TopEage="22" BottomEage="22" Scale9OriginX="102" Scale9OriginY="22" Scale9Width="4" Scale9Height="18" ctype="ImageViewObjectData">
                    <Size X="187.0000" Y="64.0000" />
                    <AnchorPoint ScaleX="1.0000" ScaleY="1.0000" />
                    <Position X="100.1972" Y="34.5261" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/yq_z_light.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="point" ActionTag="-408853076" VisibleForFrame="False" Tag="129" IconVisible="False" LeftMargin="76.1869" RightMargin="-94.1869" TopMargin="-34.9187" BottomMargin="16.9187" ctype="SpriteObjectData">
                    <Size X="18.0000" Y="18.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="85.1869" Y="25.9187" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/ui/spherical_red.png" Plist="" />
                    <BlendFunc Src="1" Dst="771" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="normal" ActionTag="-611412856" Alpha="0" Tag="127" IconVisible="False" LeftMargin="-82.9999" RightMargin="-77.0001" TopMargin="-35.3649" BottomMargin="-28.6351" TouchEnable="True" LeftEage="102" RightEage="102" TopEage="22" BottomEage="22" Scale9OriginX="102" Scale9OriginY="22" Scale9Width="4" Scale9Height="18" ctype="ImageViewObjectData">
                    <Size X="160.0000" Y="64.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="-2.9999" Y="3.3649" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/yq_z_light.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="text" ActionTag="1455480076" Tag="128" IconVisible="False" PositionPercentXEnabled="True" PositionPercentYEnabled="True" LeftMargin="-33.0000" RightMargin="-33.0000" TopMargin="-17.5000" BottomMargin="-17.5000" FontSize="23" LabelText="Eqiup" ShadowOffsetX="0.5000" ShadowOffsetY="0.5000" ctype="TextObjectData">
                    <Size X="66.0000" Y="35.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="86" G="108" B="119" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                    <OutlineColor A="255" R="255" G="0" B="0" />
                    <ShadowColor A="255" R="66" G="100" B="138" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="line" ActionTag="-1815730180" Tag="130" RotationSkewX="90.0000" RotationSkewY="90.0000" IconVisible="False" LeftMargin="-21.9516" RightMargin="20.9516" TopMargin="-19.8435" BottomMargin="-127.1565" FlipY="True" Scale9Enable="True" TopEage="14" BottomEage="20" Scale9OriginY="14" Scale9Width="1" Scale9Height="15" ctype="ImageViewObjectData">
                    <Size X="1.0000" Y="147.0000" />
                    <AnchorPoint ScaleX="0.6099" ScaleY="0.6532" />
                    <Position X="-21.3417" Y="-31.1361" />
                    <Scale ScaleX="1.0000" ScaleY="1.1131" />
                    <CColor A="255" R="255" G="255" B="255" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FileData Type="Normal" Path="Common/newUI/line_fg01.png" Plist="" />
                  </AbstractNodeData>
                  <AbstractNodeData Name="text_0" ActionTag="-74241593" VisibleForFrame="False" Tag="131" IconVisible="False" LeftMargin="-22.0000" RightMargin="-46.0000" TopMargin="-18.0003" BottomMargin="-17.9997" FontSize="24" LabelText="Eqiup" ShadowOffsetX="1.5000" ShadowOffsetY="-2.5000" ctype="TextObjectData">
                    <Size X="68.0000" Y="36.0000" />
                    <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                    <Position X="12.0000" Y="0.0003" />
                    <Scale ScaleX="1.0000" ScaleY="1.0000" />
                    <CColor A="255" R="254" G="255" B="254" />
                    <PrePosition />
                    <PreSize X="0.0000" Y="0.0000" />
                    <FontResource Type="Normal" Path="fonts/cuyabra.ttf" Plist="" />
                    <OutlineColor A="255" R="77" G="77" B="77" />
                    <ShadowColor A="255" R="26" G="57" B="101" />
                  </AbstractNodeData>
                </Children>
                <AnchorPoint />
                <Position X="85.8429" Y="286.4009" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition X="0.4796" Y="0.6226" />
                <PreSize X="0.0000" Y="0.0000" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint ScaleY="1.0000" />
            <Position X="113.6900" Y="599.5699" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.1001" Y="0.7807" />
            <PreSize X="0.1576" Y="0.5990" />
            <FileData Type="Normal" Path="Common/newUI/rw_bottom.png" Plist="" />
          </AbstractNodeData>
          <AbstractNodeData Name="second_node" ActionTag="-1100449371" Alpha="0" Tag="109" IconVisible="True" LeftMargin="314.5634" RightMargin="821.4366" TopMargin="180.8201" BottomMargin="587.1799" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <AnchorPoint />
            <Position X="314.5634" Y="587.1799" />
            <Scale ScaleX="1.0000" ScaleY="1.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition X="0.2769" Y="0.7646" />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>