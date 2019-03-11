<GameFile>
  <PropertyGroup Name="WeaponEffect_09" Type="Node" ID="c968c75c-f90e-4c62-a53b-89dcb9421904" Version="3.10.0.0" />
  <Content ctype="GameProjectContent">
    <Content>
      <Animation Duration="86" Speed="1.0000" ActivedAnimationName="attack">
        <Timeline ActionTag="-1793268513" Property="FileData">
          <TextureFrame FrameIndex="0" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10001.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="5" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10003.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="10" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10005.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="15" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10007.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="20" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10009.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="25" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10011.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="-1793268513" Property="Alpha">
          <IntFrame FrameIndex="25" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="26" Value="0">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="-453941415" Property="FileData">
          <TextureFrame FrameIndex="59" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10001.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="60" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10001.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="65" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10003.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="70" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10005.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="75" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10007.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="80" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10009.png" Plist="" />
          </TextureFrame>
          <TextureFrame FrameIndex="85" Tween="False">
            <TextureFile Type="Normal" Path="sfx/weapon/WeaponEffect09/10011.png" Plist="" />
          </TextureFrame>
        </Timeline>
        <Timeline ActionTag="-453941415" Property="Alpha">
          <IntFrame FrameIndex="59" Value="0">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="60" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="85" Value="255">
            <EasingData Type="0" />
          </IntFrame>
          <IntFrame FrameIndex="86" Value="0">
            <EasingData Type="0" />
          </IntFrame>
        </Timeline>
        <Timeline ActionTag="-453941415" Property="Position">
          <PointFrame FrameIndex="59" X="2.0000" Y="16.0000">
            <EasingData Type="0" />
          </PointFrame>
        </Timeline>
        <Timeline ActionTag="-453941415" Property="Scale">
          <ScaleFrame FrameIndex="59" X="1.0000" Y="1.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
        <Timeline ActionTag="-453941415" Property="RotationSkew">
          <ScaleFrame FrameIndex="59" X="0.0000" Y="0.0000">
            <EasingData Type="0" />
          </ScaleFrame>
        </Timeline>
      </Animation>
      <AnimationList>
        <AnimationInfo Name="attack" StartIndex="0" EndIndex="26">
          <RenderColor A="255" R="72" G="61" B="139" />
        </AnimationInfo>
        <AnimationInfo Name="hurt" StartIndex="30" EndIndex="56">
          <RenderColor A="255" R="119" G="136" B="153" />
        </AnimationInfo>
        <AnimationInfo Name="attack_2" StartIndex="60" EndIndex="86">
          <RenderColor A="255" R="255" G="248" B="220" />
        </AnimationInfo>
      </AnimationList>
      <ObjectData Name="Node" Tag="835" ctype="GameNodeObjectData">
        <Size X="0.0000" Y="0.0000" />
        <Children>
          <AbstractNodeData Name="Node_1" ActionTag="-1006431508" Tag="836" IconVisible="True" LeftMargin="-38.3057" RightMargin="38.3057" TopMargin="3.6249" BottomMargin="-3.6249" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="Sprite_1" ActionTag="-1793268513" Tag="837" IconVisible="False" LeftMargin="-82.5000" RightMargin="-86.5000" TopMargin="-112.0000" BottomMargin="-80.0000" ctype="SpriteObjectData">
                <Size X="169.0000" Y="192.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="2.0000" Y="16.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="sfx/weapon/WeaponEffect09/10007.png" Plist="" />
                <BlendFunc Src="1" Dst="1" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="-38.3057" Y="-3.6249" />
            <Scale ScaleX="1.5084" ScaleY="1.5084" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
          <AbstractNodeData Name="Node_1_0" ActionTag="573380498" Tag="831" IconVisible="True" LeftMargin="40.1298" RightMargin="-40.1298" TopMargin="-11.0049" BottomMargin="11.0049" ctype="SingleNodeObjectData">
            <Size X="0.0000" Y="0.0000" />
            <Children>
              <AbstractNodeData Name="Sprite_1" ActionTag="-453941415" Alpha="0" Tag="832" IconVisible="False" LeftMargin="-82.5000" RightMargin="-86.5000" TopMargin="-112.0000" BottomMargin="-80.0000" ctype="SpriteObjectData">
                <Size X="169.0000" Y="192.0000" />
                <AnchorPoint ScaleX="0.5000" ScaleY="0.5000" />
                <Position X="2.0000" Y="16.0000" />
                <Scale ScaleX="1.0000" ScaleY="1.0000" />
                <CColor A="255" R="255" G="255" B="255" />
                <PrePosition />
                <PreSize X="0.0000" Y="0.0000" />
                <FileData Type="Normal" Path="sfx/weapon/WeaponEffect09/10001.png" Plist="" />
                <BlendFunc Src="1" Dst="1" />
              </AbstractNodeData>
            </Children>
            <AnchorPoint />
            <Position X="40.1298" Y="11.0049" />
            <Scale ScaleX="1.5084" ScaleY="1.5084" />
            <CColor A="255" R="255" G="255" B="255" />
            <PrePosition />
            <PreSize X="0.0000" Y="0.0000" />
          </AbstractNodeData>
        </Children>
      </ObjectData>
    </Content>
  </Content>
</GameFile>