c      $Id$
      subroutine zeropar(nits)

      implicit real*8 (A-H,O-Z)

      include 'dim.h'     
      include 'acom.h'
      include 'bcom.h'
      include 'trnsfr.h'
      include 'clocks.h'
      include 'dp.h'
      include 'orbit.h'
      include 'eph.h'
      include 'glitch.h'

      integer i

      do i=1,NPAP1
         nfit(i)=0
         x(i)=0.
      enddo
	
      pmra=0.
      pmdec=0.
      pmrv=0.
      p0=0.
      p1=0.
      p2=0.
      pepoch=50000.
      posepoch=0.
      f0=0.
      f1=0.
      f2=0.
      f3=0.
      do i=1,9
         f4(i)=0.
      enddo
      px=0.
      dm=0.
      do i=1,10
         dmcof(i)=0.
      enddo
      start=0.
      finish=100000.

      do i=1,4
         a1(i)=0.
         e(i)=0.
         t0(i)=0.
         pb(i)=0.
         omz(i)=0.
      enddo
      t0asc=0.
      eps1=0.
      eps2=0.
      omdot=0.
      gamma=0.
      pbdot=0.
      si=0.
      am=0.
      am2=0.
      dr=0.
      dth=0.
      a0=0.
      b0=0.
      bp=0.
      bpp=0.
      xdot=0.
      edot=0.
      afac=0.
      om2dot=0.
      x2dot=0.
      eps1dot=0.
      eps2dot=0.

      nxoff=0
      do i=1,NJUMP
         xjdoff(1,i)=0.
         xjdoff(2,i)=0.
      enddo
      
      ngl=0
      do i=1,NGLT
         glph(i)=0.
         glf0(i)=0.
         glf1(i)=0.
         glf0d(i)=0.
         gltd(i)=0.
         glepoch(i)=0.
      enddo

      ndmcalc=0
      nfcalc=0

      nbin=0
      nplanets=0
      nclk=0
      nephem=1
      nits=1
      ncoord=1
      nell1=0

      return
      end

c=======================================================================

      subroutine rdpar(nits)

C  Free format input
C  Line structure: "[fit] key value error/comment"
C  The error/comment is ignored by TEMPO

      implicit real*8 (A-H,O-Z)

      include 'dim.h'
      include 'acom.h'
      include 'bcom.h'
      include 'trnsfr.h'
      include 'clocks.h'
      include 'tz.h'
      include 'dp.h'
      include 'orbit.h'
      include 'eph.h'
      include 'glitch.h'

      character line*80, key*8, value*24, cfit*1, temp*80

      logical seteps            ! indicate when eps1 and/or eps2
                                ! had been set
      logical setepsdot         ! indicate when eps1dot and/or eps2dot
                                ! had been set
      logical set2dot           ! indicate when om2dot and/or x2dot
                                ! had been set
      logical setecl, setequ    ! indicate when some ecliptic or
	                        ! equatorial coordinate has been set

      seteps    = .false.
      setepsdot = .false.
      set2dot   = .false.
      setecl    = .false.
      setequ    = .false.

      ll=80

      nskip = 0  ! counts parameter lines, which are skipped if TOAs are
		 !    read from this file
	
      rewind(parunit)  ! probably not needed, but a good safety check

 10   read(parunit,'(a)',end=900)line
      nskip = nskip + 1

C  Get key, value and cfit
      jn=1
      call citem(line,ll,jn,key,lk)
      if(key(1:1).eq.'#' .or. (key(1:1).eq.'C' .and. lk.eq.1))go to 10
      call upcase(key)
      call citem(line,ll,jn,value,lv)
      call citem(line,ll,jn,temp,lf)
      if(temp(1:1).eq.'#' .or. lf.eq.0)then
         cfit='0'
      else if(lf.eq.1)then
         cfit=temp(1:1)
      else
         write(*,'(''Illegal fit value: '',a)')temp(1:lf)
         stop
      endif

C  Control parameters

      if(key(1:4).eq.'NPRN')then
         read(value,*)nprnt

      else if(key(1:4).eq.'NITS')then
         read(value,*)nits

      else if(key(1:4).eq.'IBOO')then
         read(value,*)iboot

      else if(key(1:4).eq.'NDDM')then
         read(value,*)nddm

      else if(key(1:4).eq.'COOR')then
         if(value(1:5).eq.'B1950')ncoord=0

      else if(key(1:3).eq.'CLK')then
         call upcase(value)
         do i=0,nclkmax
            if(value(1:5).eq.clklbl(i)(1:5))then
               nclk=i
               go to 12
            endif
         enddo
         write(*,'(''Invalid CLK label: '',a)')value(1:5)
         stop
 12      continue

      else if(key(1:4).eq.'EPHE')then
         call upcase(value)
         do i=1,kephem
            if(value(1:5).eq.ephfile(i)(1:5)) then
		nephem=i
            	go to 14
	    endif
         enddo
         write(*,'(''Invalid EPHEM file name: '',a)')value(1:5)
         stop
 14      continue

      else if(key(1:6).eq.'TZRMJD')then
         read(value,*)tzrmjd

      else if(key(1:6).eq.'TZRFRQ')then
         read(value,*)tzrfrq

      else if(key(1:7).eq.'TZRSITE')then
         tzrsite=value(1:1)
         
      else if(key(1:5).eq.'START')then
         read(value,*)start

      else if(key(1:6).eq.'FINISH')then
         read(value,*)finish

C  Period/Frequency parameters

      else if(key(1:2).eq.'P0' .or. (key(1:1).eq.'P' .and. lk.eq.1))then
         read(value,*)p0
         read(cfit,*)nfit(2)

      else if(key(1:2).eq.'P1'.or.key(1:4).eq.'PDOT')then
         read(value,*)p1
         read(cfit,*)nfit(3)
         nfcalc = max(nfit(3),nfcalc)

      else if(key(1:2).eq.'F0' .or. (key(1:1).eq.'F' .and. lk.eq.1))then
         read(value,*)f0
         read(cfit,*)nfit(2)

      else if(key(1:2).eq.'F1')then
         read(value,*)f1
         if(cfit.ge.'A')then
            call upcase(cfit)
            nfit(3)=ichar(cfit)-55
         else
            nfit(3)=ichar(cfit)-48
         endif
         nfcalc = max(nfit(3),nfcalc)

      else if(key(1:2).eq.'F2')then
         read(value,*)f2
         read(cfit,*)nfit(4)

      else if(key(1:2).eq.'F3')then
         read(value,*)f3
         read(cfit,*)ifit
         if (ifit.gt.0) nfit(3)=max(nfit(3),3)
         nfcalc = max(nfcalc,3)

      else if(key(1:1).eq.'F' .and.
     +           key(2:2).ge.'4' .and. key(2:2).le.'9') then
        read(key(2:2),*)jj
        read(value,*)f4(jj-3)
        read(cfit,*)ifit
        if (ifit.gt.0) nfit(3)=max(nfit(3),jj)
        nfcalc = max(nfcalc,jj)

      else if(key(1:1).eq.'F' .and.
     +           key(2:2).ge.'A' .and. key(2:2).le.'C') then
        jj = ichar(key(2:2))-55  ! A=10, B=11, C=12
        read (value,*)f4(jj-3)
        read(cfit,*)ifit
        if (ifit.gt.0) nfit(3)=max(nfit(3),jj)
        nfcalc = max(nfcalc,jj)

      else if(key(1:4).eq.'PEPO')then
         read(value,*)pepoch

C  Position parameters

      else if(key(1:3).eq.'PSR')then
         psrname=value(1:12)

      else if(key(1:3).eq.'DEC')then
         call decolon(value)
         read(value,*)pdec
         read(cfit,*)nfit(5)
	 setequ = .true.

      else if(key(1:2).eq.'RA')then
         call decolon(value)
         read(value,*)pra
         read(cfit,*)nfit(6)
	 setequ = .true.

      else if(key(1:4).eq.'PMDE')then
         read(value,*)pmdec
         read(cfit,*)nfit(7)
	 setequ = .true.

      else if(key(1:4).eq.'PMRA')then
         read(value,*)pmra
         read(cfit,*)nfit(8)
         setequ = .true.

      else if(key(1:4).eq.'BETA')then
         read(value,*)pdec
         read(cfit,*)nfit(5)
	 setecl = .true.

      else if(key(1:6).eq.'LAMBDA')then
         read(value,*)pra
         read(cfit,*)nfit(6)
	 setecl = .true.

      else if(key(1:6).eq.'PMBETA')then
         read(value,*)pmdec
         read(cfit,*)nfit(7)
	 setecl = .true.

      else if(key(1:8).eq.'PMLAMBDA')then
         read(value,*)pmra
         read(cfit,*)nfit(8)
         setecl = .true.

      else if(key(1:4).eq.'PMRV')then
         read(value,*)pmrv
         read(cfit,*)nfit(36)

      else if(key(1:2).eq.'PX')then
         read(value,*)px
         read(cfit,*)nfit(17)

      else if(key(1:5).eq.'POSEP')then
         read(value,*)posepoch

      else if(key(1:3).eq.'DM0'.or.key(1:2).eq.'DM'.and.lk.eq.2)then
         read(value,*)dm
         if(cfit.le.'9')then
            itmp=ichar(cfit)-48
         else
            call upcase(cfit)
            itmp=ichar(cfit)-55
         endif
         nfit(16)=max(nfit(16),itmp)

      else if(key(1:2).eq.'DM'.and.
     +        key(3:3).ge.'1'.and.key(3:3).le.'9') then 
        read(key(3:3),*)jj
        read(value,*)dmcof(jj)
        if (cfit.gt.'0') nfit(16)=max(nfit(16),jj+1)
        ndmcalc=max(ndmcalc,jj+1)

C  Binary parameters

      else if(key(1:4).eq.'BINA')then
         call upcase(value)
         do i=1,NMODELS
            if(value(1:8).eq.bmodel(i)) goto 20
         enddo
         write(*,100) value(1:8)
 100     format(' WARNING: binary model - ',a,' - not recognized')
         goto 22         
c 20      nbin=i-1  ! ### Check this !!! (Works in Linux/Intel)
 20      nbin=i
         if(value(1:2).eq.'BT'.and.value(4:4).eq.'P')
     +      read(value,'(2x,i1)') nplanets
 22      continue

      else if(key(1:4).eq.'A1_1'.or.(key(1:2).eq.'A1'.and.lk.eq.2))then
         read(value,*)a1(1)
         read(cfit,*)nfit(9)

      else if(key(1:3).eq.'E_1 '.or.(key(1:1).eq.'E'.and.lk.eq.1))then
         read(value,*)e(1)
         read(cfit,*)nfit(10)

      else if(key(1:4).eq.'T0_1'.or.(key(1:2).eq.'T0'.and.lk.eq.2))then
         read(value,*)t0(1)
         read(cfit,*)nfit(11)

      else if(key(1:4).eq.'PB_1'.or.(key(1:2).eq.'PB'.and.lk.eq.2))then
         read(value,*)pb(1)
         read(cfit,*)nfit(12)

      else if(key(1:4).eq.'OM_1'.or.(key(1:2).eq.'OM'.and.lk.eq.2))then
         read(value,*)omz(1)
         read(cfit,*)nfit(13)

      else if(key(1:4).eq.'A1_2')then
         read(value,*)a1(2)
         read(cfit,*)nfit(26)

      else if(key(1:3).eq.'E_2 ')then
         read(value,*)e(2)
         read(cfit,*)nfit(27)

      else if(key(1:4).eq.'T0_2')then
         read(value,*)t0(2)
         read(cfit,*)nfit(28)

      else if(key(1:4).eq.'PB_2')then
         read(value,*)pb(2)
         read(cfit,*)nfit(29)

      else if(key(1:4).eq.'OM_2')then
         read(value,*)omz(2)
         read(cfit,*)nfit(30)

      else if(key(1:4).eq.'A1_3')then
         read(value,*)a1(3)
         read(cfit,*)nfit(31)

      else if(key(1:3).eq.'E_3 ')then
         read(value,*)e(3)
         read(cfit,*)nfit(32)

      else if(key(1:4).eq.'T0_3')then
         read(value,*)t0(3)
         read(cfit,*)nfit(33)

      else if(key(1:4).eq.'PB_3')then
         read(value,*)pb(3)
         read(cfit,*)nfit(34)

      else if(key(1:4).eq.'OM_3')then
         read(value,*)omz(3)
         read(cfit,*)nfit(35)

      else if(key(1:5).eq.'OMDOT')then
         read(value,*)omdot
         read(cfit,*)nfit(14)

      else if(key(1:5).eq.'GAMMA')then
         read(value,*)gamma
         read(cfit,*)nfit(15)

      else if(key(1:5).eq.'PBDOT')then
         read(value,*)pbdot
         read(cfit,*)nfit(18)

      else if(key(1:5).eq.'PPNGA')then
         read(value,*)nfit(19)

      else if(key(1:2).eq.'SI')then
         read(value,*)si
         read(cfit,*)nfit(20)

      else if(key(1:4).eq.'MTOT')then
         read(value,*)am
         read(cfit,*)nfit(21)

      else if(key(1:2).eq.'M2')then
         read(value,*)am2
         read(cfit,*)nfit(22)

      else if(key(1:5).eq.'DTHET')then
         read(value,*)dth
         read(cfit,*)nfit(23)

      else if(key(1:4).eq.'XDOT')then
         read(value,*)xdot
         read(cfit,*)nfit(24)

      else if(key(1:4).eq.'EDOT')then
         read(value,*)edot
         read(cfit,*)nfit(25)

      else if(key(1:6).eq.'XOMDOT')then
         read(value,*)xomdot
         read(cfit,*)nfit(37)

      else if(key(1:6).eq.'XPBDOT')then
         read(value,*)xpbdot
         read(cfit,*)nfit(38)

      else if(key(1:6).eq.'OM2DOT')then
         read(value,*)om2dot
         read(cfit,*)nfit(39)
         set2dot=.true.

      else if(key(1:5).eq.'X2DOT')then
         read(value,*)x2dot
         read(cfit,*)nfit(40)
         set2dot=.true.

      else if(key(1:4).eq.'EPS1'.and.lk.eq.4)then
         read(value,*)eps1
         read(cfit,*)nfit(10)
         seteps=.true.

      else if(key(1:4).eq.'EPS2'.and.lk.eq.4)then
         read(value,*)eps2
         read(cfit,*)nfit(13)
         seteps=.true.

      else if(key(1:5).eq.'T0ASC'.and.lk.eq.5)then
         read(value,*)t0asc
         read(cfit,*)nfit(11)         
         
      else if(key(1:7).eq.'EPS1DOT'.and.lk.eq.7)then
         read(value,*)eps1dot
         read(cfit,*)nfit(39)
         setepsdot=.true.

      else if(key(1:7).eq.'EPS2DOT'.and.lk.eq.7)then
         read(value,*)eps2dot
         read(cfit,*)nfit(40)
         setepsdot=.true.

C  Fixed binary parameters

      else if(key(1:2).eq.'DR')then
         read(value,*)dr

      else if(key(1:2).eq.'A0')then
         read(value,*)a0

      else if(key(1:2).eq.'B0')then
         read(value,*)b0

      else if(key(1:2).eq.'BP')then
         read(value,*)bp

      else if(key(1:3).eq.'BPP')then
         read(value,*)bpp

      else if(key(1:4).eq.'AFAC')then
         read(value,*)afac

C  Glitches

      else if(key(1:6).eq.'GLEP_1')then
         read(value,*)glepoch(1)

      else if(key(1:6).eq.'GLPH_1')then
         read(value,*)glph(1)
         read(cfit,*)nfit(61)

      else if(key(1:6).eq.'GLF0_1')then
         read(value,*)glf0(1)
         read(cfit,*)nfit(62)

      else if(key(1:6).eq.'GLF1_1')then
         read(value,*)glf1(1)
         read(cfit,*)nfit(63)

      else if(key(1:7).eq.'GLF0D_1')then
         read(value,*)glf0d(1)
         read(cfit,*)nfit(64)

      else if(key(1:6).eq.'GLTD_1')then
         read(value,*)gltd(1)
         read(cfit,*)nfit(65)

      else if(key(1:6).eq.'GLEP_2')then
         read(value,*)glepoch(2)

      else if(key(1:6).eq.'GLPH_2')then
         read(value,*)glph(2)
         read(cfit,*)nfit(66)

      else if(key(1:6).eq.'GLF0_2')then
         read(value,*)glf0(2)
         read(cfit,*)nfit(67)

      else if(key(1:6).eq.'GLF1_2')then
         read(value,*)glf1(2)
         read(cfit,*)nfit(68)

      else if(key(1:7).eq.'GLF0D_2')then
         read(value,*)glf0d(2)
         read(cfit,*)nfit(69)

      else if(key(1:6).eq.'GLTD_2')then
         read(value,*)gltd(2)
         read(cfit,*)nfit(70)

      else if(key(1:6).eq.'GLEP_3')then
         read(value,*)glepoch(3)

      else if(key(1:6).eq.'GLPH_3')then
         read(value,*)glph(3)
         read(cfit,*)nfit(71)

      else if(key(1:6).eq.'GLF0_3')then
         read(value,*)glf0(3)
         read(cfit,*)nfit(72)

      else if(key(1:6).eq.'GLF1_3')then
         read(value,*)glf1(3)
         read(cfit,*)nfit(73)

      else if(key(1:7).eq.'GLF0D_3')then
         read(value,*)glf0d(3)
         read(cfit,*)nfit(74)

      else if(key(1:6).eq.'GLTD_3')then
         read(value,*)gltd(3)
         read(cfit,*)nfit(75)

      else if(key(1:6).eq.'GLEP_4')then
         read(value,*)glepoch(4)

      else if(key(1:6).eq.'GLPH_4')then
         read(value,*)glph(4)
         read(cfit,*)nfit(76)

      else if(key(1:6).eq.'GLF0_4')then
         read(value,*)glf0(4)
         read(cfit,*)nfit(77)

      else if(key(1:6).eq.'GLF1_4')then
         read(value,*)glf1(4)
         read(cfit,*)nfit(78)

      else if(key(1:7).eq.'GLF0D_4')then
         read(value,*)glf0d(4)
         read(cfit,*)nfit(79)

      else if(key(1:6).eq.'GLTD_4')then
         read(value,*)gltd(4)
         read(cfit,*)nfit(80)

      else if(key(1:4).eq.'HEAD') then
c        (Do nothing) (DJN)

      else if(key(1:3).eq.'TOA') then   ! end of parameter list (DJN)
	goto 900

      else 
         if(key.ne.'        ')
     +      write(*,'('' Unrecognized input key: '',a)')key

      endif

      goto 10

 900  continue

      if(nfit(61)+nfit(62)+nfit(63)+nfit(64)+nfit(65).ne.0)ngl=1
      if(nfit(66)+nfit(67)+nfit(68)+nfit(69)+nfit(70).ne.0)ngl=2
      if(nfit(71)+nfit(72)+nfit(73)+nfit(74)+nfit(75).ne.0)ngl=3
      if(nfit(76)+nfit(77)+nfit(78)+nfit(79)+nfit(80).ne.0)ngl=4

C  Warnings

      if(nfit(3).lt.0.or.nfit(3).gt.12.or.nfcalc.lt.0.or.nfcalc.gt.12)
     +   write(*,'('' WARNING: Fit parameter for F1 out of range'')')

      if(nfit(16).lt.0.or.nfit(16).gt.10.or.ndmcalc.lt.0
     +   .or.ndmcalc.gt.1)
     +   write(*,'('' WARNING: Fit parameter for DM out of range'')')

      if(setecl)then
	 if(setequ)then
	    write (*,'(''ERROR: cannot mix ecliptic and equatorial'',
     +	         '' coordinates'')')
	    stop
	 else
	    eclcoord=.true.
	 endif
      endif

      if(nbin.eq.0.and.(nfit(9).ne.0.or.nfit(10).ne.0.or.nfit(11).ne.0
     +     .or.nfit(12).ne.0.or.nfit(13).ne.0))then
         write(*,'('' WARNING: Binary model not defined'')')
      endif

      if(nbin.ne.8 .and. set2dot)then
         write(*,'('' WARNING: No OM2DOT or X2DOT in '',a,'' !!!'')') 
     +        bmodel(nbin)
      endif

      if(nbin.ne.9 .and. setepsdot)then
         write(*,'('' WARNING: No EPS1DOT or EPS2DOT in '',a,'' !!!'')') 
     +        bmodel(nbin)
      endif

      if(nbin.eq.9)then
         if(seteps .and. t0asc.eq.0.)then
            write(*,'('' WARNING: T0ASC not set, use T0ASC=T0 !!!'')')
            t0asc=t0(1)
            t0(1)=0.
         endif

         if(.not.seteps .and. t0(1).eq.0.)then
            write(*,'('' WARNING: T0 not set, use T0=T0ASC !!!'')')
            t0(1)=t0asc
            t0asc=0.
         endif

         if((nfit(14).ne.0.or.omdot.ne.0.) .and. setepsdot)then
            write(*,'('' WARNING: omdot is not used !!!'')')
            omdot=0.
            nfit(14)=0
         endif

         if((nfit(25).ne.0.or.edot.ne.0.) .and. setepsdot)then         
            write(*,'('' WARNING: edot is not used !!!'')')
            edot=0.
            nfit(25)=0
         endif
      endif

      return
      end

c=======================================================================

      subroutine decolon(w)

C  Remove ':' from line

      character w*(*), ww*80
      j=0
      ww=' '
      do i=1,len(w)
         if(w(i:i).ne.':')then
            j=j+1
            ww(j:j)=w(i:i)
         endif
      enddo
      w=ww
      return
      end

c=======================================================================

      subroutine upcase(w)

C  Converts string (up to first blank) to upper case.

      character*(*) w
      do 10 i=1,len(w)
         if(w(i:i).eq.' ') go to 20
         j=ichar(w(i:i))
         if(j.ge.97.and.j.le.122) w(i:i)=char(j-32)
 10   continue
 20   return
      end
