#define SONGS 7

uniform float time;
uniform sampler2D t_audio;
uniform vec4 links[SONGS];
uniform vec4 activeLink;
uniform vec4 hoveredLink;

uniform sampler2D t_matcap;
uniform sampler2D t_normal;
uniform sampler2D t_text;
uniform float textRatio;
uniform float interfaceRadius;

uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;

uniform float songVal;

varying vec3 vPos;
varying vec3 vCam;
varying vec3 vNorm;

varying vec3 vMNorm;
varying vec3 vMPos;

varying vec2 vUv;

vec3 bulbPos[5];


$uvNormalMap
$semLookup
$hsv


// Branch Code stolen from : https://www.shadertoy.com/view/ltlSRl
// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

const float MAX_TRACE_DISTANCE = 6.0;             // max trace distance
const float INTERSECTION_PRECISION = 0.001;        // precision of the intersection
const int NUM_OF_TRACE_STEPS = 30;
const float PI = 3.14159;

const vec3 moonPos = vec3( -3. , 3. , -3.);



$smoothU
$opU
$sdCapsule
$sdBox
$sdSphere
$sdHexPrism



float centerBlob1( vec3 pos  ){

  //pos.x += .1 * sin( pos.x * 20. );
  //pos.y += .1 * sin( pos.y * 20. );
  //pos.z += .1 * sin( pos.z * 20. );

  float dis = length( texture2D( t_audio , vec2( mod(length( pos ) *1.,.5) , 0.) ) );

  float b = sdSphere( pos , .3 );
 
  return  b - dis * .1 * ((songVal / float(SONGS))*3.+1.);


}



float centerBlob2( vec3 pos  ){

  float m = 100000.;

  float dis = length( texture2D( t_audio , vec2( abs(sin(length( pos ) * 2.)), 0.) ) );

  for( int i = 0; i < 5; i++ ){

    float d = sdSphere( pos - bulbPos[i], .2 + dis * .1 );

    m = smoothU( vec2( m , 0. ) , vec2( d , 0. ) , .2 ).x;

  }
 
  return  m; //b - dis * .2;
}

float centerBlob3( vec3 pos  ){

  float dis = length( texture2D( t_audio , vec2( abs(sin(length( pos ) * 2.)), 0.) ) );

  float d = sdHexPrism( pos , vec2( .2 + dis * .1 , 1. + dis * .1  )) ;

 
  return  d; //b - dis * .2;
}

//--------------------------------
// Modelling 
//--------------------------------
vec2 map( vec3 pos ){  

    vec3 og = pos;

    vec2 res = vec2( 1000000. , 0. );




    for( int i = 0; i < SONGS; i++ ){
      float c = sdSphere( pos  - links[i].xyz , .25 );
      res = smoothU( res , vec2(  c , float( i ) + 10. ) , .1 );
      vec2 caps = vec2( sdCapsule( pos , links[i].xyz ,  vec3( 0. ) , .01) , 20. );
      res = smoothU( res , caps , .1 ) ;
    }


    vec2 caps;

    if( hoveredLink.w > .1 ){
      caps = vec2( sdSphere( pos  - hoveredLink.xyz , .3 ) , 110. );
      //caps = vec2( sdCapsule( pos , hoveredLink.xyz ,  hoveredLink.xyz * .8 , .03 ) , 30. );
      res = smoothU( res , caps , .1 ) ;
    }



    // interface tracing
    if( activeLink.w > .1 ){
      caps = vec2( sdCapsule( pos , activeLink.xyz ,  vec3( 0. ) , .01) , 60. );
      res = smoothU( res , caps , .3 ) ;
    }


 
    vec2 cb = vec2( centerBlob1( pos ), 1. );

    res = smoothU( res , cb , 1. + (songVal / float(SONGS))  );



    //text

    float moon = sdSphere( og -  moonPos , 2.4 );
   // res = opU( res , vec2( moon , 1000.));

    float text = sdBox( og - vec3( 0. , -1 , 1.2 ) , vec3( textRatio * .2 , .2 , .01 ));
    //res = opU( res , vec2( text , 100.));


  if( pos.z < 1. ){
    float modA = 1.-(songVal / float(SONGS));
    vec3 newPos = mod( pos , vec3( modA));
    vec3 difxyz = pos.xyz - activeLink.xyz;
    float bg = sdSphere( newPos - vec3( modA * .5 ) ,modA*.5 * .4 / length(difxyz) );
    //res = opU( res , vec2(bg, 10. / length( difxyz)) );
  }

    return res;
    
}


$calcIntersection
$calcNormal
$calcAO




void main(){

  for( int i = 0; i < 5; i++ ){

    float l = float( i );

    vec3 p = vec3( sin( time * ( l + 1. ) * .1 + l ),  cos( time * ( 5. -  l )  * .02  + l ) , sin( .02 * time * ( 3. + l ) + l ) );

    p *= .8;

    bulbPos[i] = p;


  }

  vec3 fNorm = uvNormalMap( t_normal , vPos , vUv , vNorm , 10.6 , .5 * songVal / float(SONGS)  );

  vec3 ro = vPos;
  vec3 rd = normalize( vPos - vCam );

  vec3 p = vec3( 0. );
  vec3 col =  vec3( 0. );

  float m = max(0.,dot( -rd , fNorm ));

  //col += fNorm * .5 + .5;

  vec3 refr = refract( rd , fNorm , .8 ) ;

  vec2 res = calcIntersection( ro , refr );

  if( res.y > -.5 ){

    p = ro + refr * res.x;
    vec3 n = calcNormal( p );

    //col += n * .5 + .5;


    vec3 mat = texture2D( t_matcap , semLookup( refr , n , modelViewMatrix , normalMatrix ) ).xyz;


    col += mat;
    col *= hsv( res.y * .1 , .3 + (songVal / float(SONGS)) * .7 , 1. );

    if( res.y == 100. ){

      vec2 lookup = p.xy;
      //lookup.x += .5;
      lookup.x /= textRatio;
      lookup.x /= .4;
      lookup.x += .5;
      lookup.y += 1.2;
      lookup.y *= 2.3;
      //lookup.y *= 1.4;

      vec3 tVal = texture2D( t_text , lookup ).xyz;
      col = hsv(length(tVal) * .4 + time ,.5,1.) * tVal;
      //col += vec3( 1.1 );
    }

    if( res.y == 1000. ){
      col = vec3( pow( 1. - dot( -n , rd ) , 4.) );
    }

    if( res.y > 100. ){
      col = vec3(1.,1.,1.) * mat;// normalize(mat);
    }

    vec3 aCol =texture2D( t_audio , vec2( dot( -n , rd ) , 0.) ).xyz;

    col *= aCol;
    //col -= texture2D( t_audio , vec2(  abs( n.x ) , 0. ) ).xyz;

  }else{
    discard;
  }



  if( abs( vUv.x - .5)> .48 || abs( vUv.y - .5)> .48 ){
    col += vec3( .5 );

  }

  gl_FragColor = vec4( col , 1. );

}










