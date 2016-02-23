function [c sampleRate s cacheUpdated]=getClip(s)
if isempty(s.clip)
    %disp(sprintf('caching %s',s.name))

    switch s.type
        case 'binaryWhiteNoise'
            s.clip = rand(1,s.numSamples)>.5;
        case 'gaussianWhiteNoise'
            s.clip = randn(1,s.numSamples);
        case 'uniformWhiteNoise'
            s.clip = rand(1,s.numSamples);
        case 'allOctaves'
            outFreqs=[];
            for i=1:length(s.fundamentalFreqs)
                done=0;
                thisFreq=s.fundamentalFreqs(i);
                while ~done
                    if thisFreq<=s.maxFreq
                        outFreqs=[outFreqs thisFreq];
                        thisFreq=2*thisFreq;
                    else
                        done=1;
                    end
                end
            end
            freqs=unique(outFreqs);
            raw=repmat(2*pi*[0:s.numSamples]/s.numSamples,length(freqs),1);
            s.clip = sum(sin(diag(freqs)*raw));
            
        case 'tone'
            toneDuration=500;
            s.numSamples = s.sampleRate*toneDuration/1000;
            t=1:s.numSamples;
            t=t/s.sampleRate;
            tone=sin(2*pi*t*s.freq);
            s.clip = tone;
            
        case 'toneLaser'
            toneDuration=500;
            s.numSamples = s.sampleRate*toneDuration/1000;
            t=1:s.numSamples;
            t=t/s.sampleRate;
            tone=sin(2*pi*t*s.freq);
            s.clip = tone;
        case 'CNMToneTrain'
            %train of pure tones, all at start freq, except last one is at
            %end freq. duration and isi specified in setProtocolCNM
            startfreq=s.freq(1);
            endfreq=s.freq(2);
            numtones=s.freq(3);
            isi=s.freq(4);
            toneDuration=s.freq(5);
            s.numSamples = s.sampleRate*toneDuration/1000;
            t=1:s.numSamples;
            t=t/s.sampleRate;
            starttone=sin(2*pi*t*startfreq);
            endtone=sin(2*pi*t*endfreq);
            silence=zeros(1, 44.1*isi);
            train=[];
            for i=1:numtones
            train=[train starttone silence];    
            end
            train=[train endtone];

            s.clip = train;
        case 'freeCNMToneTrain'
            %train of pure tones, all at start freq
            %duration and isi specified in setProtocolCNM
            startfreq=s.freq(1);
            endfreq=s.freq(2);
            numtones=s.freq(3);
            isi=s.freq(4);
            toneDuration=s.freq(5);
            s.numSamples = s.sampleRate*toneDuration/1000;
            t=1:s.numSamples;
            t=t/s.sampleRate;
            starttone=sin(2*pi*t*startfreq);
            %endtone=sin(2*pi*t*endfreq);
            silence=zeros(1, s.sampleRate*isi/1000);
            train=[];
            for i=1:numtones-1
            train=[train starttone silence];
            end    
            train=[train starttone];
            s.clip = train;
        case 'wmToneWN'
            startsound=s.freq(1); %if 0, tone first, if 1, WN first
            endsound=s.freq(2); %if 0, tone 2nd, if 1, WN 2nd 
            freq=s.freq(3);
            isi=s.freq(4);
            toneDuration=s.freq(5);
            s.numSamples = s.sampleRate*toneDuration/1000;
            t=1:s.numSamples;
            t=t/s.sampleRate;
            tone=sin(2*pi*t*freq);
            WN = randn(1,s.numSamples);
            if startsound
                starttone = tone;
            else
                starttone = WN;
            end
            if endsound
                endtone = tone;
            else
                endtone = WN;
            end
            silence=zeros(1, s.sampleRate*isi/1000);
            train=[];
            train=[train starttone silence];    
            train=[train endtone];
            
            s.clip = train;
            
        case 'wmReadWav'
            s.clip = s.freq;
            a = s.sampleRate;

        case 'phonemeWav'
            [sad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\sadshifted-allie.wav'); %left
            %[dad, fs] =wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie.wav'); %right 
            %old stimulus - not ideally aligned - changed to new file with
            %50ms silence added to beginning of dad
            [dad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie-aligned.wav'); %right
            if s.freq
                s.clip = sad.';
            else 
                s.clip = dad.';
            end
            
        case 'phonemeWavLaser'
            [sad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\sadshifted-allie.wav'); %left
            %[dad, fs] =wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie.wav'); %right 
            %old stimulus - not ideally aligned - changed to new file with
            %50ms silence added to beginning of dad
            [dad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie-aligned.wav'); %right
            if s.freq
                s.clip = sad.';
            else 
                s.clip = dad.';
            end
            
        case 'phonemeWavLaserMulti'
            [sad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\sadshifted-allie.wav'); %left
            %[dad, fs] =wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie.wav'); %right 
            %old stimulus - not ideally aligned - changed to new file with
            %50ms silence added to beginning of dad
            [dad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie-aligned.wav'); %right
            if s.freq
                s.clip = sad.';
            else 
                s.clip = dad.';
            end    

        case 'phonemeWavReversedReward'
            [sad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\sadshifted-allie.wav'); %left
            %[dad, fs] =wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie.wav'); %right 
            %old stimulus - not ideally aligned - changed to new file with
            %50ms silence added to beginning of dad
            %reversed rewards for this soundType - to test stimulus vs
            %motor effect of laser
            [dad, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\dadshifted-allie-aligned.wav'); %right
            if s.freq
                s.clip = dad.';
            else 
                s.clip = sad.';
            end
            
        case {'speechWav', 'speechWavLaser', 'speechWavLaserMulti', 'speechWavReversedReward'} %note reversed is not reversed here
            %replace speech sounds with intro multiple /g/ /b/ comparison
            %load audio files within if structure so not loading every time. g = left, b = right
            %random integers from uniform distribution to choose which sound
            r1 = randi(3,1);
            r2 = randi(3,1);
            
            if s.freq
                if r1 == 1;
                    if r2 == 1;
                    [gI1, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\gI\gI1.wav');
                    s.clip = gI1.';
                    elseif r2 == 2;
                    [gI2, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\gI\gI2.wav');
                    s.clip = gI2.';
                    elseif r2 == 3;
                    [gI3, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\gI\gI3.wav');
                    s.clip = gI3.';
                    end
                elseif r1 == 2;
                    if r2 == 1;
                    [ga1, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\ga\ga1.wav');
                    s.clip = ga1.';
                    elseif r2 == 2;
                    [ga2, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\ga\ga2.wav');
                    s.clip = ga2.';
                    elseif r2 == 3;
                    [ga3, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\ga\ga3.wav');
                    s.clip = ga3.';
                    end
                elseif r1 == 3;
                    if r2 == 1;
                    [go1, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\go\go1.wav');
                    s.clip = go1.';
                    elseif r2 == 2;
                    [go2, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\go\go2.wav');
                    s.clip = go2.';
                    elseif r2 == 3;
                    [go3, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\go\go3.wav');
                    s.clip = go3.';
                    end
                end
            else 
                if r1 == 1;
                    if r2 == 1;
                    [bI1, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\bI\bI1.wav');
                    s.clip = bI1.';
                    elseif r2 == 2;
                    [bI2, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\bI\bI2.wav');
                    s.clip = bI2.';
                    elseif r2 == 3;
                    [bI3, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\bI\bI3.wav');
                    s.clip = bI3.';
                    end
                elseif r1 == 2;
                    if r2 == 1;
                    [ba1, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\ba\ba1.wav');
                    s.clip = ba1.';
                    elseif r2 == 2;
                    [ba2, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\ba\ba2.wav');
                    s.clip = ba2.';
                    elseif r2 == 3;
                    [ba3, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\ba\ba3.wav');
                    s.clip = ba3.';
                    end
                elseif r1 == 3;
                    if r2 == 1;
                    [bo1, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\bo\bo1.wav');
                    s.clip = bo1.';
                    elseif r2 == 2;
                    [bo2, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\bo\bo2.wav');
                    s.clip = bo2.';
                    elseif r2 == 3;
                    [bo3, fs] = audioread('C:\Users\nlab\Desktop\ratrixSounds\phonemes\Jonny\CV\bo\bo3.wav');
                    s.clip = bo3.';
                    end
                end
            end
            
        case 'warblestackWav'  
            startsound=s.freq(1); %if 0, warble first, if 1, WN first
            endsound=s.freq(2); %if 0, tone 2nd, if 1, WN 2nd 
            isi=s.freq(4);
            [warble, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\WMsounds\warble_stack.wav');
            [harmonic, fs] = wavread('C:\Users\nlab\Desktop\ratrixSounds\WMsounds\harmonic_stack.wav');
            if startsound
                starttone = warble.';
            else
                starttone = harmonic.';
            end
            if endsound
                endtone = warble.';
            else
                endtone = harmonic.';
            end
            silence=zeros(1, s.sampleRate*isi/1000);
            train=[];
            train=[train starttone silence];    
            train=[train endtone];
            s.clip = train;
        case 'tritones'
            s.clip = getClip(soundClip('annonymous','allOctaves',[s.fundamentalFreqs tritones(s.fundamentalFreqs)],s.maxFreq));
        case 'dualChannel'
            s.clip(1,:) = getClip(s.leftSoundClip);
            s.clip(2,:) = getClip(s.rightSoundClip);
            s.amplitude(1) = s.leftAmplitude;
            s.amplitude(2) = s.rightAmplitude;
        case 'empty'
            s.clip = []; %zeros(1,s.numSamples);
        otherwise
            error('unknown soundClip type')
    end

    %For all channels, normalize
    for i=1:size(s.clip,1)
        s.clip(i,:)=s.clip(i,:)-mean(s.clip(i,:));
        s.clip(i,:)=s.clip(i,:)/max(abs(s.clip(i,:)))*s.amplitude(i);
    end
    s.clip(isnan(s.clip))=0;
    
    cacheUpdated=1;

else
    %disp(sprintf('already cached %s',s.name))
    cacheUpdated=0;
end
c=s.clip;
sampleRate=s.sampleRate;

function t=tritones(freqs)
t=freqs*2.^(6/12); % to get i halfsteps over freq, use freq*2.^[i/12]