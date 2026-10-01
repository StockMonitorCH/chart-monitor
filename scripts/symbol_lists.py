"""
symbol_lists.py – Screener symbol universe for Chart Monitor.
Single source of truth for all index symbol lists.
"""

SP500 = [
    'MMM','AOS','ABT','ABBV','ACN','ADBE','AMD','AES','AFL','A',
    'APD','ABNB','AKAM','ALB','ARE','ALGN','ALLE','LNT','ALL','GOOGL',
    'GOOG','MO','AMZN','AMCR','AEE','AEP','AXP','AIG','AMT','AWK',
    'AMP','AME','AMGN','APH','ADI','ANSS','AON','APA','AAPL','AMAT',
    'APTV','ACGL','ADM','ANET','AJG','AIZ','T','ATO','ADSK','ADP',
    'AZO','AVB','AVY','AXON','BKR','BALL','BAC','BAX','BDX','WRB',
    'BBY','BIIB','BLK','BX','BK','BA','BKNG','BWA','BSX','BMY',
    'AVGO','BR','BRO','BLDR','BG','CDNS','CZR','CPT','CPB','COF',
    'CAH','KMX','CCL','CARR','CAT','CBOE','CBRE','CDW','CE','COR',
    'CNC','CDAY','CF','CRL','SCHW','CHTR','CVX','CMG','CB','CHD',
    'CI','CINF','CTAS','CSCO','C','CFG','CLX','CME','CMS','KO',
    'CTSH','CL','CMCSA','CAG','COP','ED','STZ','CEG','COO','CPRT',
    'GLW','CPAY','COST','CTRA','CRWD','CCI','CSX','CMI','CVS','DHR',
    'DRI','DVA','DE','DELL','DAL','DVN','DXCM','FANG','DLR','DFS',
    'DG','DLTR','D','DPZ','DOV','DTE','DUK','DD','EMN','ETN',
    'EBAY','ECL','EIX','EW','EA','ELV','EMR','ENPH','ETR','EOG',
    'EPAM','EQT','EFX','EQIX','EQR','ESS','EL','ETSY','EG','EXAS',
    'EXPE','EXPD','EXR','XOM','FFIV','FDS','FICO','FAST','FRT','FDX',
    'FIS','FITB','FSLR','FE','FI','F','FTNT','FTV','FOXA','FOX',
    'BEN','FCX','GRMN','IT','GE','GEHC','GEV','GEN','GNRC','GD',
    'GIS','GM','GPC','GILD','GS','HAL','HIG','HAS','HCA','DOC',
    'HSIC','HSY','HES','HPE','HLT','HOLX','HD','HON','HRL','HST',
    'HWM','HPQ','HUBB','HUM','HBAN','HII','IBM','IEX','IDXX','ITW',
    'INCY','IR','ICE','IP','IPG','ISRG','IVZ','INVH','IQV','IRM',
    'JBHT','JBL','JKHY','J','JNJ','JCI','JPM','JNPR','K','KVUE',
    'KDP','KEY','KEYS','KMB','KIM','KMI','KLAC','KHC','KR','LHX',
    'LH','LRCX','LW','LVS','LDOS','LEN','LLY','LIN','LYV','LKQ',
    'LMT','L','LOW','LULU','LYB','MTB','MRO','MPC','MKTX','MAR',
    'MMC','MLM','MAS','MA','MTCH','MKC','MCD','MCK','MDT','MRK',
    'META','MET','MTD','MGM','MCHP','MU','MSFT','MAA','MRNA','MHK',
    'MOH','TAP','MDLZ','MPWR','MNST','MCO','MS','MOS','MSI','MSCI',
    'NDAQ','NTAP','NFLX','NEM','NWSA','NWS','NEE','NKE','NI','NDSN',
    'NSC','NTRS','NOC','NCLH','NRG','NUE','NVDA','NVR','NXPI','ORLY',
    'OXY','ODFL','OMC','ON','OKE','ORCL','OTIS','PCAR','PKG','PLTR',
    'PANW','PH','PAYX','PAYC','PYPL','PNR','PEP','PFE','PCG','PM',
    'PSX','PNW','PNC','POOL','PPG','PPL','PFG','PG','PGR','PLD',
    'PRU','PEG','PTC','PSA','PHM','PWR','QCOM','DGX','RL','RJF',
    'RTX','O','REG','REGN','RF','RSG','RMD','RVTY','ROK','ROL',
    'ROP','ROST','RCL','SPGI','CRM','SBAC','SLB','STX','SRE','NOW',
    'SHW','SPG','SWKS','SJM','SW','SNA','SOLV','SO','LUV','SWK',
    'SBUX','STT','STLD','STE','SYK','SYF','SNPS','SYY','TMUS','TROW',
    'TTWO','TPR','TRGP','TGT','TEL','TDY','TFX','TER','TSLA','TXN',
    'TXT','TMO','TJX','TSCO','TT','TDG','TRV','TRMB','TFC','TYL',
    'TSN','USB','UBER','UDR','UHS','UNP','UAL','UPS','URI','UNH',
    'VLO','VTR','VLTO','VRSN','VRSK','VZ','VRTX','V','VST','VNO',
    'VTRS','VICI','VMC','WAB','WBA','WMT','DIS','WBD','WM','WAT',
    'WEC','WFC','WELL','WST','WDC','WY','WHR','WMB','WTW','GWW',
    'WYNN','XEL','XYL','YUM','ZBRA','ZBH','ZTS','APO','SMCI','DAY',
    'CTLT','TECH','CNX','CMA','VNT','VIAV',
]

NASDAQ100 = [
    'MSFT','AAPL','NVDA','AMZN','META','TSLA','GOOGL','GOOG','AVGO','COST',
    'NFLX','AMD','CSCO','ADBE','QCOM','INTU','PEP','TMUS','TXN','AMAT',
    'HON','ISRG','AMGN','BKNG','VRTX','REGN','SBUX','ADI','MU','KLAC',
    'MDLZ','LRCX','PANW','GILD','SNPS','CDNS','CTAS','ASML','MRVL','INTC',
    'MELI','PYPL','ORLY','MNST','FTNT','NXPI','CHTR','WDAY','ABNB','DXCM',
    'ADSK','MCHP','PAYX','AEP','FAST','VRSK','CSX','EXC','ODFL','KDP',
    'IDXX','CPRT','ROP','ROST','EA','BIIB','CEG','KHC','GEHC','ON',
    'FANG','CTSH','DLTR','BKR','ANSS','NDAQ','DDOG','ZS','TTWO','XEL',
    'ILMN','MRNA','WBD','ALGN','ARM','DASH','TEAM','TTD','SMCI','CSGP',
    'SIRI','CCEP','CDW','PCAR','CRWD','SBAC','GFS','LULU','RIVN','PLTR',
]

NASDAQ_EXTRA = [
    # Cloud / SaaS
    'NET','SNOW','MDB','OKTA','DOCN','BILL','GTLB','PD','ZI','APPN',
    'SMAR','PCOR','FROG','S','BASE','VERX',
    # AI / Quantum
    'IONQ','QUBT','RGTI','QBTS','SOUN','AI','PATH','QLYS','BBAI',
    # EV / Clean Energy
    'LCID','NIO','LI','XPEV','BLNK','CHPT','EVGO','BE','PLUG','ARRY','NOVA','RUN',
    # Space / Defense Tech
    'RKLB','ASTS','LUNR','ACHR','JOBY','IRDM','KTOS','AVAV','AXON',
    # Crypto / Fintech
    'COIN','MSTR','MARA','RIOT','HOOD','SOFI','AFRM','UPST','LMND',
    # Biotech
    'NVAX','BNTX','BEAM','EDIT','CRSP','NTLA','SRPT','HALO',
    # Gaming / Social / Consumer
    'RBLX','SPOT','RDDT','SNAP','PINS','DUOL','DKNG','CVNA',
    # Semiconductors (mid-cap)
    'WOLF','SITM','AEIS','ONTO','AZTA','CRUS','AMBA','POWI','RMBS',
]

RUSSELL1000 = list(dict.fromkeys([
    # Technology
    'AAOI','ACMR','ADEA','AGYS','ALKT','ALRM','AMSC','ANGI','APPF','ARLO',
    'AVNW','BAND','BLKB','CALX','COHU','EGHT','ENFN','ENVX','EVTC','EXLS',
    'FIVN','FSLY','JAMF','LPSN','MARA','MITK','NCNO','NEOG','NTGR','PERI',
    'PLAB','PRFT','RPAY','RSKD','SYNC','TACT','TTGT','UPLD','VIAV','VIRT',
    'XPER','SCSC','BIGC','DUOS','EVCM','FOUR','GRIN','HCAT','IIIV','INFU',
    'IOTS','MLNK','MNTV','NABL','NTCT','PDFS','PRTS',
    'ACLS','AEIS','AMKR','AOSL','AZTA','CRUS','DAVA','DIOD','EGAN','EMKR',
    'FORM','GDYN','HOLI','IDCC','ITRN','LSCC','LUNA','MGNI','MKSI','MTSI',
    'POWI','RMBS','SLAB','SMTC','SSYS','STAA','TTEC','TTMI','UCTT','VERI',
    'VICR','VSEC','YEXT','EVBG','EPAY','CLFD','FCFS','EZPW','PCYG','TELA',
    'LYTS','DMRC','AXTI','AVID','INVA','FORR','GSIT','SWIR','ATNI','NXGN',
    'NEON','NNOX','WRAP','CMPR','AMSWA','AVPT','CEVA','CLPS','CNXN',
    'DGII','IOSP','SILC','SIGA','MTRN','CBPX','TPCS',
    # Healthcare / Biotech
    'ACRS','ADMA','ADUS','AFMD','AGEN','AGIO','ALEC','AMPH','ARWR','AXNX',
    'BCRX','BFLY','CALT','CNMD','CORT','CPSI','DVAX','FATE','FOLD','HIMS',
    'HALO','IMNM','IRMD','KYMR','LGND','MDXG','NKTR','NTLA','NVAX',
    'PDCO','PRAX','RCKT','SAVA','SWAV','TMDX','VKTX','VRCA',
    'AKRO','ARDX','BTAI','CRSP','EDIT','GLYC','HRMY',
    'IMVT','ITCI','MNKD','MRUS','ONCR','PTGX','SAGE',
    'ACAD','ACST','ADPT','AKBA','ALDX','ALPN','AMRX','ANAB',
    'APLS','ARAV','ARCUS','ARQT','ARVN','ASND','ASPN','ATRC',
    'AVNS','AVXL','AXGN','AXSM','BDTX','BHVN','BOLT','BPMC','CARA',
    'CBAY','CDMO','CDTX','CHRS','CLDX','CMRX','CNCE','COGT','CPRX',
    'CRNX','CUTR','ETNB','FBIO','FLGT','FULC','GERN','GRTS','HRTX',
    'INMD','INSM','IONS','JNCE','KPTI','KRYS','LGMD',
    'MGNX','NUVB','OCGN','AVEO','KROS',
    'PRPH','VNDA','XNCR','YMAB','ZGNX','ZYXI',
    # Financials / Banking
    'AROW','AMNB','BHLB','BFIN','CASH','CNOB','ESSA','FRME','HTBK','KRNY',
    'LKFN','MBWM','NBTB','OCFC','OFG','PFBC','PRK','RNST','SASR','TBK',
    'TRMK','WASH','BCAL','BSVN','BWFG','CFFN','FFBH','FLIC','HONE','SMBC',
    'ACNB','AMSF','ATLC','ATLO','BFST','BKSC','BMTC','BOCH','BPOP',
    'BRKL','BUSE','BWB','CBNK','CCBG','CFFI','CHMG','CLBK',
    'COBZ','COOP','DCOM','EGBN','ENVA','FBNC','FFIN','FISI',
    'FNLC','FRST','GNTY','GSBC','HAFC','HBCP','HFWA','HOPE','HTLF','IBCP',
    'IBTX','INDB','ISBA','LAKE','LBAI','LCNB','MCBC','MFIN','MSBI',
    'NFBK','OPBK','PFIS','PNFP','PPBI','PRAA',
    'SFBS','TBNK','TCBK','TFSL','TOWN','UVSP','WAFD','WSBC','FFIC',
    'CATC','CCNE',
    # Consumer / Retail
    'BOOT','HIBB','BJRI','PLAY','CAKE','WING','JACK','RCII','SNBR',
    'LESL','ASO','CATO','LOVE','EVRI','CBRL',
    'GOLF','CVGW','DORM','HELE','HGV','JJSF','LANC','MATW',
    'PETS','PLCE','POWL','PRGS','SCVL',
    'ARKO','BBSI','BGFV','CALM','CHUY','CONN','CPRI',
    'CRVL','DENN','EXPR','FRPT','GIII',
    'HAIN','HWKN','JBSS','JOUT','KFRC','KIRK','LCII','LGIH','LOCO','LSTR',
    'NATH','NDLS','PLOW','PLXS','RCKY','RRGB','SMPL','SONO',
    'CHEF','CRSR','DXPE',
    # Energy
    'AMPY','ARCH','BTU','CIVI','GPOR','MTDR','MNRL','NOG','SBOW',
    'CEIX','BATL','FLNG','HPK','REX','SGU','VAALCO',
    'DMLP','INSW','LBRT','PARR','PBF','PTEN','PVAC',
    'SWN','TALO','TELL','VNOM','WTTR',
    # Industrials
    'AAON','AVAV','DNOW','ECVT','GMS','HURN','KTOS','LMAT',
    'MYRG','PRIM','SHYF','SKYW','SPXC','TGI','TITN','TREX',
    'WLDN','ARCB','ATRI','CVEO','DY','EXPO','GEO','HAYN','HXL',
    'AHCO','ALCO','AMWD','APOG','ASGN','ASTE','BCPC','CECO',
    'CSGS','CVCO','DFIN','FELE','FNKO','GATX','GENC','GLDD','HEES',
    'HTLD','IIIN','IRBT','JELD','JOE','KELYA','KNSL','LAWS',
    'MATX','MRTN','MRCY','NVEE','OSIS','PATK','PLPC','STRL',
    'NTIC','OTTR','MGEE',
    # Real Estate
    'AIRC','ALEX','BRT','BNL','EPR','FCPT','GMRE','GTY','IIPR','ILPT',
    'INN','KRG','NXRT','PSTL','SAFE','SBRA','STAG','SVC','UHT','UNIT',
    'AOMR','BXMT','EPRT','GOOD','JBGS','KREF','LAND','MACK',
    'NREF','NTST','NYMT','OLP','ORCC','PLYM','ROIC','TRNO','APLE',
]))

NYSE200 = [
    # Precious Metals & Mining
    'GOLD','AEM','WPM','KGC','AGI','BTG','SA','CDE','HL','EXK',
    'FSM','SILV','MAG','PAAS','USAS',
    # Energy - Oil & Gas Independents
    'PR','NOG','CHRD','CIVI','CPE','TALO','SM','CRC','GPOR',
    'ARCH','BTU','AMR','VAALCO','HPK','REX','SGU',
    # Mortgage REITs
    'AGNC','NLY','TWO','RC','BXMT','ARR','PMT','MFA','NYMT',
    # Equity REITs (not in S&P 500)
    'STAG','KRG','FCPT','GTY','AIRC','INN','NXRT','EPR',
    'BRT','UNIT','PSTL','SBRA','SVC','UHT','ILPT','SAFE','OLP',
    'GOOD','GMRE','ROIC','TRNO','PLYM','LXP','NNN','EPRT','NTST',
    # Consumer / Retail
    'ANF','GPS','HBI','GES','CRI','ASO','LESL','BOOT','PLCE',
    'GIL','RH','AEO','PVH','CATO','DORM','HGV','SNBR','HIBB',
    # Community Banking
    'OFG','PRK','RNST','SASR','TBK','TRMK','WASH','BCAL',
    'BSVN','BWFG','AROW','AMNB','BHLB','MBWM','NBTB','FFBH',
    # Industrials / Engineering
    'AAON','GMS','DNOW','TGI','TITN','SHYF','TREX','PRIM',
    'MYRG','WLDN','ARCB','DY','HAYN','GEO','KFRC','POWL',
    # Healthcare
    'DOCS','HQY','SIGA','PDCO','HIMS','SWAV','TMDX','ACCD',
    'NUVN','CHRS','IMVT',
    # Technology (mid-cap)
    'YEXT','VERI','SSYS','NNOX','WRAP','CMPR','TELA','LYTS',
    'DMRC','ATNI','NXGN','NEON','PCYG','TPCS','AXTI',
    # International / ADRs on NYSE
    'SE','NU','BTI','CNH','STM','BEKE','YMM','GRAB',
    'PBR','VALE','ITUB','SID','BTG',
]

CAC40 = [
    'AC.PA','AI.PA','AIR.PA','ALO.PA','AXA.PA','BNP.PA','EN.PA',
    'CAP.PA','CA.PA','ACA.PA','DSY.PA','ENGI.PA','EL.PA','RMS.PA',
    'KER.PA','LR.PA','OR.PA','MC.PA','ML.PA','ORA.PA','RI.PA','PUB.PA',
    'RNO.PA','SAF.PA','SGO.PA','SAN.PA','SU.PA','GLE.PA','STM.PA',
    'HO.PA','TTE.PA','URW.PA','VIE.PA','DG.PA','VIV.PA','WLN.PA',
    'MT.AS','BN.PA','SW.PA','STLA.PA',
]

NIKKEI225 = [
    '6758.T','9984.T','7203.T','6861.T','4063.T','8306.T','9432.T',
    '6367.T','7267.T','8035.T','4502.T','9433.T','6594.T','4568.T',
    '8316.T','7741.T','4519.T','8411.T','4523.T','6702.T',
    '7751.T','8766.T','7733.T','6645.T','8058.T','9022.T','8031.T',
    '7011.T','6501.T','6503.T','9020.T','4901.T','7201.T','2914.T',
    '8001.T','9101.T','6857.T','5401.T','8002.T','7269.T','4661.T',
    '6902.T','8053.T','3382.T','9202.T','6954.T','7752.T','4507.T',
    '4503.T','8630.T','1925.T','2802.T','9613.T','6724.T','5711.T',
    '4188.T','8601.T','3407.T','7270.T','5201.T','4452.T','6471.T',
    '2503.T','9735.T','8309.T','5108.T','4042.T','6701.T','7912.T',
    '8591.T','9502.T','5333.T','7832.T','4151.T','8750.T','6473.T',
    '9766.T','7731.T','2501.T','4004.T','5714.T','8725.T','9983.T',
    '4578.T','6981.T','6526.T','6098.T','6326.T','6841.T',
]

TSX = [
    'ENB.TO','RY.TO','TD.TO','BNS.TO','BMO.TO','CM.TO','MFC.TO','SLF.TO',
    'SU.TO','CNQ.TO','TRP.TO','PPL.TO','IMO.TO','CVE.TO','AEM.TO','WPM.TO',
    'K.TO','ABX.TO','FNV.TO','OVV.TO','ERF.TO','CPG.TO',
    'CNR.TO','CP.TO','WCN.TO','ATD.TO','L.TO','MRU.TO','GIL.TO',
    'QSR.TO','DOL.TO','TIH.TO','WFG.TO','IFC.TO','IAG.TO',
    'SHOP.TO','CSU.TO','OTEX.TO','BAM.TO','PWF.TO','GWO.TO','FFH.TO','POW.TO',
    'TRI.TO','RCI-B.TO','BCE.TO','T.TO','SJ.TO','MG.TO','AC.TO',
    'CAR-UN.TO','REI-UN.TO','AP-UN.TO','NTR.TO','AGI.TO','KL.TO',
    'PEY.TO','TVE.TO','BTE.TO','MEG.TO','ARX.TO','BEI-UN.TO','HR-UN.TO',
]

ASX200 = [
    'BHP.AX','CBA.AX','CSL.AX','ANZ.AX','WBC.AX','NAB.AX','WES.AX','MQG.AX',
    'TLS.AX','RIO.AX','WOW.AX','FMG.AX','STO.AX','WDS.AX','AMC.AX',
    'TCL.AX','COL.AX','REA.AX','ALL.AX','GMG.AX','APA.AX','ASX.AX','SHL.AX',
    'QBE.AX','IAG.AX','MPL.AX','AZJ.AX','ORA.AX','SCG.AX','DXS.AX',
    'GPT.AX','SGP.AX','MGR.AX','AGL.AX','ORG.AX','S32.AX','ILU.AX','LYC.AX',
    'MIN.AX','PLS.AX','NHC.AX','WHC.AX','SEK.AX','CAR.AX','IEL.AX',
    'ALU.AX','TNE.AX','PME.AX','XRO.AX','WTC.AX','CPU.AX','EBO.AX',
    'RHC.AX','EVN.AX','SFR.AX','BSL.AX','JHX.AX','LLC.AX','SUL.AX',
    'VEA.AX','ALD.AX','TWE.AX','SGM.AX','IPL.AX','CHC.AX','VCX.AX',
    'BWP.AX','CWY.AX','CLW.AX','HLS.AX','NEC.AX','NXT.AX',
    'HVN.AX','JBH.AX','MTS.AX','ARB.AX','BLD.AX','NST.AX',
]

STI = [
    'D05.SI','U11.SI','O39.SI','Z74.SI','C6L.SI','S68.SI',
    'C09.SI','BN4.SI','S63.SI','U96.SI','BS6.SI','V03.SI',
    'S59.SI','J36.SI','C07.SI','H78.SI','G13.SI','F34.SI',
    'A17U.SI','C38U.SI','M44U.SI','ME8U.SI','N2IU.SI',
    'T82U.SI','K71U.SI','BUOU.SI','9CI.SI','Y92.SI',
    'E5H.SI','RW0U.SI',
]

NIFTY50 = [
    'RELIANCE.NS','TCS.NS','HDFCBANK.NS','INFY.NS','ICICIBANK.NS',
    'HINDUNILVR.NS','ITC.NS','SBIN.NS','BHARTIARTL.NS','KOTAKBANK.NS',
    'LT.NS','AXISBANK.NS','ASIANPAINT.NS','BAJFINANCE.NS','MARUTI.NS',
    'WIPRO.NS','HCLTECH.NS','SUNPHARMA.NS','TITAN.NS','ULTRACEMCO.NS',
    'POWERGRID.NS','NTPC.NS','ADANIPORTS.NS','BAJAJFINSV.NS','TECHM.NS',
    'NESTLEIND.NS','ONGC.NS','COALINDIA.NS','DRREDDY.NS','CIPLA.NS',
    'BRITANNIA.NS','DIVISLAB.NS','EICHERMOT.NS','GRASIM.NS','HEROMOTOCO.NS',
    'HINDALCO.NS','INDUSINDBK.NS','JSWSTEEL.NS','M&M.NS','TATAMOTORS.NS',
    'TATASTEEL.NS','TATACONSUM.NS','APOLLOHOSP.NS','BPCL.NS','SBILIFE.NS',
    'HDFCLIFE.NS','BAJAJ-AUTO.NS','BEL.NS','TRENT.NS','ETERNAL.NS',
]

HANGSENG = [
    '0700.HK','9988.HK','0939.HK','1299.HK','3690.HK',
    '1398.HK','2318.HK','0941.HK','0005.HK','0388.HK',
    '1810.HK','0011.HK','0016.HK','0002.HK','0003.HK',
    '0006.HK','0012.HK','0017.HK','0027.HK','0066.HK',
    '0175.HK','0267.HK','0288.HK','0291.HK','0386.HK',
    '0669.HK','0688.HK','0762.HK','0823.HK','0857.HK',
    '0883.HK','0960.HK','1038.HK','1044.HK','1093.HK',
    '1109.HK','1113.HK','1177.HK','1211.HK','1288.HK',
    '1876.HK','1928.HK','2020.HK','2269.HK','2313.HK',
    '2382.HK','2388.HK','2628.HK','3328.HK','3988.HK',
    '6618.HK','6690.HK','6862.HK','9618.HK','9633.HK',
    '9888.HK','9999.HK','1347.HK','0101.HK','1024.HK',
]

EWZ = [
    'VALE3.SA','PETR4.SA','ITUB4.SA','PETR3.SA','BBDC4.SA',
    'ABEV3.SA','B3SA3.SA','BBAS3.SA','WEGE3.SA','RENT3.SA',
    'SUZB3.SA','RDOR3.SA','LREN3.SA','JBSS3.SA','UGPA3.SA',
    'ELET3.SA','ELET6.SA','CMIG4.SA','BBSE3.SA','PRIO3.SA',
    'SBSP3.SA','VIVT3.SA','CCRO3.SA','GGBR4.SA','BPAC11.SA',
    'EQTL3.SA','TOTS3.SA','RAIL3.SA','BRFS3.SA','CSAN3.SA',
    'CSNA3.SA','MULT3.SA','ALUP11.SA','ENBR3.SA','HYPE3.SA',
    'RADL3.SA','FLRY3.SA','ENEV3.SA','CPLE6.SA','IGTI11.SA',
    'BEEF3.SA','MRVE3.SA','CMIN3.SA','HAPV3.SA','EMBR3.SA',
    'MGLU3.SA','TAEE11.SA','NTCO3.SA','PETZ3.SA','YDUQ3.SA',
]

SCANDINAVIA = [
    # Schweden – OMXS30
    'ABB.ST','ALFA.ST','ASSA-B.ST','ATCO-A.ST','ATCO-B.ST','AZN.ST',
    'BOL.ST','ERIC-B.ST','EVO.ST','ESSITY-B.ST','GETI-B.ST','HEXA-B.ST',
    'HM-B.ST','INVE-B.ST','NDA-SE.ST','NIBE-B.ST','SAND.ST','SCA-B.ST',
    'SEB-A.ST','SECU-B.ST','SKA-B.ST','SKF-B.ST','SHB-A.ST','SWED-A.ST',
    'TEL2-B.ST','TELIA.ST','VOLV-B.ST','SINCH.ST',
    # Dänemark – OMXC25
    'NOVO-B.CO','MAERSK-B.CO','DSV.CO','ORSTED.CO','CARL-B.CO',
    'COLO-B.CO','DEMANT.CO','GMAB.CO','VWS.CO','PNDORA.CO',
    'TRYG.CO','AMBU-B.CO','GN.CO','ROCK-B.CO','NSIS-B.CO',
    'BAVA.CO','FLS.CO','DFDS.CO','ISS.CO','RBREW.CO',
    # Norwegen – OBX
    'EQNR.OL','DNB.OL','MOWI.OL','TEL.OL','NHY.OL','AKRBP.OL',
    'ORK.OL','YAR.OL','SALM.OL','AKER.OL','SUBC.OL','NEL.OL',
    'GOGL.OL','STB.OL','SCATC.OL','BAKKA.OL','TOMRA.OL',
    'SRBANK.OL','ATEA.OL','AFG.OL',
    # Finnland – OMXH25
    'NOKIA.HE','FORTUM.HE','NESTE.HE','SAMPO.HE','UPM.HE',
    'METSO.HE','ELISA.HE','TIETO.HE','OUTOKUMPU.HE','HUHTAMAKI.HE',
    'KONECRANES.HE','KEMIRA.HE','KOJAMO.HE','KNEBV.HE','NDA-FI.HE',
    'WRTBV.HE','ORNBV.HE','KESKOB.HE',
]

OSTEUROPA = [
    # Polen – WIG20
    'PKN.WA','PKO.WA','PEO.WA','PZU.WA','KGH.WA','LPP.WA',
    'CDR.WA','DNP.WA','MBK.WA','OPL.WA','PGE.WA','SANPL.WA',
    'TPE.WA','ALR.WA','CCC.WA','JSW.WA','MIL.WA','XTB.WA',
    'ALE.WA','KETY.WA',
    # Österreich – ATX
    'EBS.VI','OMV.VI','VOE.VI','VIG.VI','RBI.VI','AMS.VI',
    'WIE.VI','FLUG.VI','POST.VI','EVN.VI','BAWAG.VI','SBO.VI',
    'UQA.VI','S1.VI','ANDR.VI','TKA.VI','DO.VI','ATS.VI',
]

DAX40 = [
    'ADS.DE','AIR.DE','ALV.DE','BAS.DE','BAYN.DE','BMW.DE','BNR.DE','CBK.DE','CON.DE',
    'DB1.DE','DBK.DE','DHL.DE','DTE.DE','DTG.DE','EOAN.DE','ENR.DE','FRE.DE','HEIG.DE',
    'HEN3.DE','HNR1.DE','IFX.DE','KBX.DE','MBG.DE','MRK.DE','MTX.DE','MUV2.DE',
    'P911.DE','PAH3.DE','QIA.DE','RHM.DE','RWE.DE','SAP.DE','SHL.DE','SIE.DE',
    'SRT3.DE','SY1.DE','VOW3.DE','VNA.DE','ZAL.DE',
]

SMI20 = [
    'ABBN.SW','ALC.SW','GEBN.SW','GIVN.SW','HOLN.SW',
    'BAER.SW','KNIN.SW','LONN.SW','NESN.SW','NOVN.SW',
    'PGHN.SW','CFR.SW','ROG.SW','SDZ.SW','SCHP.SW',
    'SIKA.SW','SOON.SW','SLHN.SW','SREN.SW','UBSG.SW',
    'ZURN.SW',
]

FTSE100 = [
    'AAL.L','ABF.L','ADM.L','AHT.L','ANTO.L','AZN.L','AUTO.L','AV.L',
    'BA.L','BARC.L','BATS.L','BDEV.L','BKG.L','BP.L','BRBY.L',
    'CCH.L','CNA.L','CPG.L','CRDA.L','DCC.L','DGE.L',
    'DPLM.L','EMG.L','EXPN.L','EZJ.L','FERG.L','FLTR.L','FRES.L',
    'GLEN.L','GSK.L','HIK.L','HLN.L','HLMA.L','HSBA.L','HWDN.L',
    'IAG.L','IHG.L','III.L','IMB.L','IMI.L',
    'JD.L','KGF.L','LAND.L','LGEN.L','LLOY.L','LSEG.L',
    'MKS.L','MNDI.L','MNG.L','MRO.L','NG.L','NWG.L','NXT.L','OCDO.L',
    'PHNX.L','PRU.L','PSH.L','PSN.L','PSON.L','REL.L','RIO.L','RKT.L',
    'RMV.L','RR.L','SBRY.L','SDR.L','SGE.L','SGRO.L',
    'SHEL.L','SMIN.L','SMT.L','SN.L','SSE.L','STAN.L','STJ.L',
    'SVT.L','TSCO.L','TW.L','ULVR.L','UU.L','VTY.L','VOD.L',
    'WEIR.L','WPP.L','WTB.L',
]

# Deduplicated union of US symbols only (for Finnhub fetching)
US_SYMBOLS_ORDERED = list(dict.fromkeys(
    SP500 + NASDAQ100 + NASDAQ_EXTRA + RUSSELL1000 + NYSE200
))

# Deduplicated union of all non-US symbols (fetched via yfinance)
EU_SYMBOLS_ORDERED = list(dict.fromkeys(
    DAX40 + SMI20 + FTSE100 + CAC40 + NIKKEI225 + TSX + ASX200 +
    STI + NIFTY50 + HANGSENG + EWZ + SCANDINAVIA + OSTEUROPA
))

# All symbols combined
ALL_SYMBOLS_ORDERED = US_SYMBOLS_ORDERED + EU_SYMBOLS_ORDERED

INDEX_MAP = {
    'sp500':        SP500,
    'nasdaq100':    NASDAQ100,
    'nasdaq_extra': NASDAQ_EXTRA,
    'russell1000':  RUSSELL1000,
    'nyse200':      NYSE200,
    'dax40':        DAX40,
    'smi20':        SMI20,
    'ftse100':      FTSE100,
    'cac40':        CAC40,
    'nikkei225':    NIKKEI225,
    'tsx':          TSX,
    'asx200':       ASX200,
    'sti':          STI,
    'nifty50':      NIFTY50,
    'hangseng':     HANGSENG,
    'ewz':          EWZ,
    'scandinavia':  SCANDINAVIA,
    'osteuropa':    OSTEUROPA,
}
