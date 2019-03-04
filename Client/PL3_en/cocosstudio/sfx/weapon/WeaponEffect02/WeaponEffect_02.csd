<GameFile>
  <PropertyGroup Name="WeaponEffect_02" Type="Node" ID="a54fa1ad-4132-4680-9480-48bb7c478288" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="25" Speed="1.0000" ActivedAnimationName="attack">
        <Timeline ActionTag="131550208" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect02/10001.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="5" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect02/10003.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="10" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect02/10005.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="15" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect02/10007.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="20" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect02/10009.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="24" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect02/10009.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="25" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect02/10011.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="131550208" Property="Position">
          <PointFrame FrameIndex="24" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="131550208" Property="Scale">
          <ScaleFrame FrameIndex="24" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="131550208" Property="RotationSkew">
          <ScaleFrame FrameIndex="24" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="131550208" Property="Alpha">
          <IntFrame FrameIndex="24" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="25" Value="0">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="attack" StartIndex="0" EndIndex="25">
          <RenderColor A="255" R="250" G="235" B="215" />
        </AnimationInfo>
        <AnimationInfo Name="hurt" StartIndex="30" EndIndex="55">
          <RenderColor A="255" R="0" G="255" B="127" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="814" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="Node_1" ActionTag="1343197985" Tag="815" IconVisible="True" LeftMargin="8.2244" RightMargin="-8.2244" TopMargin="2.2080" BottomMargin="-2.2080" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="Sprite_1" ActionTag="131550208" Tag="816" IconVisible="False" LeftMargin="-79.5000" RightMargin="-79.5000" TopMargin="-77.0000" BottomMargin="-77.0000" ctype="SpriteObjectData">
                <Size X="159.0000" Y="154.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="136" G="237" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="sfx/weapon/WeaponEffect02/10003.png" Plist="" />
                <BlendFunc Src="770" Dst="1" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="8.2244" Y="-2.2080" />
            <Scale ScaleX="3.5000" ScaleY="3.5000" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>