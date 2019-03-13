<GameFile>
  <PropertyGroup Name="WeaponEffect_04" Type="Node" ID="e5ff84e6-1465-4cdc-b138-f1cec2020900" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="20" Speed="1.0000">
        <Timeline ActionTag="505050389" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect04/10001.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="5" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect04/10003.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="10" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect04/10005.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="15" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect04/10007.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="20" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect04/10009.png" Plist="" />
          </TextureFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="attack" StartIndex="0" EndIndex="20">
          <RenderColor A="255" R="220" G="220" B="220" />
        </AnimationInfo>
        <AnimationInfo Name="hurt" StartIndex="25" EndIndex="45">
          <RenderColor A="255" R="255" G="160" B="122" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="823" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="Node_1" ActionTag="1086249584" Tag="824" IconVisible="True" LeftMargin="-46.0802" RightMargin="46.0802" TopMargin="-29.2171" BottomMargin="29.2171" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="Sprite_1" ActionTag="505050389" Tag="825" IconVisible="False" LeftMargin="-50.9999" RightMargin="-105.0001" TopMargin="-58.0002" BottomMargin="-97.9998" ctype="SpriteObjectData">
                <Size X="156.0000" Y="156.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="27.0001" Y="-19.9998" />
                <Scale ScaleX="1.6648" ScaleY="1.6648" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="sfx/weapon/WeaponEffect04/10001.png" Plist="" />
                <BlendFunc Src="770" Dst="1" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="-46.0802" Y="29.2171" />
            <Scale ScaleX="2.0000" ScaleY="2.0000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>