import React, { useState } from "react";
import "../index.css";
import { debugData } from "../utils/debugData";

import { RadioChannelData } from "../typings";
import { Volume2, VolumeX, Mic, MicOff, SendHorizontal  } from "lucide-react";
import { useNuiEvent } from "../hooks/useNuiEvent";
import radioImage from '../../assets/radio-latest.png';
import { fetchNui } from "../utils/fetchNui";

import { cn } from "../utils/misc";

// This will set the NUI to visible if we are
// developing in browser
debugData([
  {
    action: "setVisible",
    data: true,
  },
]);

const App: React.FC = () => {
  const [animate, setAnimate] = useState(false)
  const [radioEnabled, setRadioEnabled] = useState<boolean>(false);
  const [primRadioData, setPrimRadioData] = useState<RadioChannelData>({
      value: null,
      connected: false,
      muted: false,
      radioType: 'prim',
  })
  const [secRadioData, setSecRadioData] = useState<RadioChannelData>({
      value: null,
      connected: false,
      muted: false,
      radioType: 'sec'
  })
  const [terRadioData, setTerRadioData] = useState<RadioChannelData>({
      value: null,
      connected: false,
      muted: false,
      radioType: 'ter'
  })

  const [radioVolume, setRadioVolume] = useState(50);

  const UpdateRadioVolume = (event: React.ChangeEvent<HTMLInputElement>) => {
      const value = event.target.value;
      setRadioVolume(Number(value));
  }

  const UpdatedRadioVolume = () => {
      fetchNui('radio:updateVolume', {volume : Number(radioVolume)})
  }

  const powerButton = () => {
      fetchNui('radio:toggleRadio').then(resp => {
          setRadioEnabled(resp === 'on' && true || false)
      })
  }

  useNuiEvent('radio:initData', (data : any) => {
      Object.keys(data).map((currentValue) => {
        if (currentValue === 'primRadioData') {
            setPrimRadioData({
                value: data[currentValue].value,
                connected: data[currentValue].connected,
                radioType: data[currentValue].radioType,
                muted: data[currentValue].muted
            })
        } else if (currentValue === 'secRadioData') {
            setSecRadioData({
                value: data[currentValue].value,
                connected: data[currentValue].connected,
                radioType: data[currentValue].radioType,
                muted: data[currentValue].muted
            })
        } else if (currentValue === 'terRadioData') {
            setTerRadioData({
                value: data[currentValue].value,
                connected: data[currentValue].connected,
                radioType: data[currentValue].radioType,
                muted: data[currentValue].muted
            })
        } else if (currentValue === 'radioVolume') {
            console.log(Number(data.radioVolume))
            setRadioVolume(Number(data.radioVolume))
        }
      })
      setAnimate(true);
  })

  useNuiEvent('radio:updateUI', (data : any) => {
      const rType = data.rType;

      if (rType == 'prim') {
        setPrimRadioData({
            value: data.value,
            connected: data.connected,
            radioType: rType,
            muted: data.muted
        })
      }else if (rType == 'sec') {
        setSecRadioData({
            value: data.value,
            connected: data.connected,
            radioType: rType,
            muted: data.muted
        })
      }else if (rType == 'ter') {
        setTerRadioData({
            value: data.value,
            connected: data.connected,
            radioType: rType,
            muted: data.muted
        })
      }
  });

  const handleChannelMute = async (radioType : string) => {
      fetchNui<{ rType: string; rState: boolean }>('radio:handleMute', {radio: radioType});
  }

  const handleChannelConnect = async (radioType: string, channel: number | null) => {
      fetchNui<{ rType: string; rState: boolean }>('radio:changeChannel', {radio: radioType, channel: channel});
  }

  const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>, radioType : string) => {
      const value = event.target.value;

      // Allow only valid numbers with up to 2 decimal places
      if (/^\d*\.?\d{0,1}$/.test(value)) {
          let numericValue = parseFloat(value);

          if (isNaN(numericValue)) {
              numericValue = 0; // Handle invalid number
          } else if (numericValue < 0) {
              numericValue = 0; // Handle value below min
          } else if (numericValue > 1000) {
              numericValue = 1000; // Handle value above max
          }

          // Update the correct radio data
          switch (radioType) {
            case "prim":
              setPrimRadioData((prev) => ({ ...prev, value: parseFloat(numericValue.toFixed(1)) }));
              break;
            case "sec":
              setSecRadioData((prev) => ({ ...prev, value: parseFloat(numericValue.toFixed(1)) }));
              break;
            case "ter":
              setTerRadioData((prev) => ({ ...prev, value: parseFloat(numericValue.toFixed(1)) }));
              break;
            default:
              break;
          }
      }
  };

  return (
    <>
      <div className="grid-container">
        <div className={`radio ${animate ? 'animate' : ''}`}>
          {radioEnabled && (
            <div className='screen'>
              <div className="flex flex-col justify-center gap-2 h-1/2 mx-2">
              {/* FIRST CHANNEL INPUT */}
                <div className={cn('relative flex rounded-r overflow-hidden border-l-4 text-2xl border-purple-300 shadow-md', primRadioData.connected==true && 'border-green-500')}>
                  <input type="number" id="search" 
                      onChange={(event) => handleInputChange(event, primRadioData.radioType)}
                      value={primRadioData.value || ''} 
                      min='0.0' max='1000.0' 
                      step=".1"
                      className="outline-none block w-full p-2 ps-4 text-black font-bold border border-gray-300  bg-white border-none dark:placeholder-gray-400 dark:text-black" 
                      placeholder="0" 
                  />
                  <span className="px-1 py-1 text-gray-800 bg-white">MHz</span>
                  <button type="submit" 
                      className="outline-none text-black bg-white font-medium text-sm px-1" 
                      formNoValidate 
                      onClick={() => handleChannelConnect(primRadioData.radioType, primRadioData.value)}
                  > 
                      <SendHorizontal size={16} />
                      {/* {primRadioData.connected && (
                          <Link2Off size={16} color="red"/>
                      ) || (<Link2 size={16} color="green"/>)} */}
                  </button>
                  <button type="submit" 
                      disabled={!primRadioData.connected} 
                      className="outline-none text-black bg-white font-medium text-sm px-1" formNoValidate 
                      onClick = {() => handleChannelMute(primRadioData.radioType)}
                  >
                    {primRadioData.muted && (<MicOff size={16} color={`${primRadioData.connected ? 'red' : 'black'}`}/>) || <Mic size={16} color={`${primRadioData.connected ? 'green' : 'black'}`}/>}
                  </button>
                </div>
                <div className={cn('relative flex rounded-r overflow-hidden border-l-4 text-2xl border-purple-300 shadow-md', secRadioData.connected==true && 'border-green-500')}>
                  <input type="number" id="search" 
                      onChange={(event) => handleInputChange(event, secRadioData.radioType)}
                      value={secRadioData.value || ''} 
                      min='0.0' max='1000.0' 
                      step=".1"
                      className="outline-none block w-full p-2 ps-4 text-black font-bold border border-gray-300  bg-white border-none dark:placeholder-gray-400 dark:text-black" 
                      placeholder="0" 
                  />
                  <span className="px-1 py-1 text-gray-800 bg-white">MHz</span>
                  <button type="submit" 
                      className="outline-none text-black bg-white font-medium text-sm px-1" 
                      formNoValidate 
                      onClick={() => handleChannelConnect(secRadioData.radioType, secRadioData.value)}
                  >
                      <SendHorizontal size={16} />
                      {/* {secRadioData.connected && (
                          <Link2Off size={16} color="red"/>
                      ) || (<Link2 size={16} color="green"/>)} */}
                  </button>
                  <button type="submit" 
                      disabled={!secRadioData.connected} 
                      className="outline-none text-black bg-white font-medium text-sm px-1" formNoValidate 
                      onClick = {() => handleChannelMute(secRadioData.radioType)}
                  >
                    {secRadioData.muted && (<MicOff size={16} color={`${secRadioData.connected ? 'red' : 'black'}`}/>) || <Mic size={16} color={`${secRadioData.connected ? 'green' : 'black'}`}/>}
                  </button>
                </div>
                <div className={cn('relative flex rounded-r overflow-hidden border-l-4 text-2xl border-purple-300 shadow-md', terRadioData.connected==true && 'border-green-500')}>
                  <input type="number" id="search" 
                      onChange={(event) => handleInputChange(event, terRadioData.radioType)}
                      value={terRadioData.value || ''} 
                      min='0.0' max='1000.0' 
                      step=".1"
                      className="outline-none block w-full p-2 ps-4 text-black font-bold border border-gray-300  bg-white border-none dark:placeholder-gray-400 dark:text-black" 
                      placeholder="0" 
                  />
                  <span className="px-1 py-1 text-gray-800 bg-white">MHz</span>
                  <button type="submit" 
                      className="outline-none text-black bg-white font-medium text-sm px-1" 
                      formNoValidate 
                      onClick={() => handleChannelConnect(terRadioData.radioType, terRadioData.value)}
                  >
                      <SendHorizontal size={16} />
                      {/* {terRadioData.connected && (
                          <Link2Off size={16} color="red"/>
                      ) || (<Link2 size={16} color="green"/>)} */}
                  </button>
                  <button type="submit" 
                      disabled={!terRadioData.connected} 
                      className="outline-none text-black bg-white font-medium text-sm px-1" formNoValidate 
                      onClick = {() => handleChannelMute(terRadioData.radioType)}
                  >
                      {terRadioData.muted && (
                          <MicOff size={16} color={`${terRadioData.connected ? 'red' : 'black'}`}/>
                        ) || <Mic size={16} color={`${terRadioData.connected ? 'green' : 'black'}`}/>}
                  </button>
                </div>

              </div>
              <div className="flex items-center justify-center gap-2 mx-2">
                <VolumeX size={30} className="text-white" />
                <input 
                    type="range" 
                    min={0}
                    max={100}
                    value={radioVolume}
                    className="volumeRange shadow-md w-full max-w-xs h-1 bg-white rounded-lg appearance-none cursor-pointer range-lg" 
                    onChange={UpdateRadioVolume}
                    onMouseUp={UpdatedRadioVolume}
                />
                <Volume2 size={30} className="text-white" />
              </div>
            </div>
          )}
          <img src={radioImage} alt="Radio" />
          <button className="toggle-radio" onClick={powerButton} ></button>
        </div>
      </div>
    </>
  );
};

export default App;
