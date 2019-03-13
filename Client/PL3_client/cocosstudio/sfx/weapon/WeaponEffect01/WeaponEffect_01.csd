<GameFile>
  <PropertyGroup Name="WeaponEffect_01" Type="Node" ID="e0416805-4ef5-4e4e-bdec-2469934f7d3b" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="42" Speed="1.0000" ActivedAnimationName="attack">
        <Timeline ActionTag="1342022191" Property="Position">
          <PointFrame FrameIndex="42" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="1342022191" Property="Scale">
          <ScaleFrame FrameIndex="42" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="1342022191" Property="RotationSkew">
          <ScaleFrame FrameIndex="42" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="1342022191" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10001.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="5" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10003.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="10" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10005.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="15" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10007.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="20" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10009.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="25" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10011.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="30" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10013.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="35" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10015.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="40" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10017.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="42" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect01/10017.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="1342022191" Property="Alpha">
          <IntFrame FrameIndex="40" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="42" Value="0">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="attack" StartIndex="0" EndIndex="42">
          <RenderColor A="255" R="255" G="255" B="224" />
        </AnimationInfo>
        <AnimationInfo Name="hurt" StartIndex="45" EndIndex="87">
          <RenderColor A="255" R="175" G="238" B="238" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="811" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="Node_1" ActionTag="-1519044305" Tag="812" IconVisible="True" LeftMargin="0.6798" RightMargin="-0.6798" TopMargin="10.4217" BottomMargin="-10.4217" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="Sprite_1_0" ActionTag="1342022191" Tag="1235" IconVisible="False" LeftMargin="-78.0000" RightMargin="-78.0000" TopMargin="-72.0000" BottomMargin="-72.0000" ctype="SpriteObjectData">
                <Size X="156.0000" Y="144.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="sfx/weapon/WeaponEffect01/10003.png" Plist="" />
                <BlendFunc Src="1" Dst="1" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="0.6798" Y="-10.4217" />
            <Scale ScaleX="1.5000" ScaleY="1.5000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>