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

# Deduplicated union of EU symbols only (for Twelve Data fetching)
EU_SYMBOLS_ORDERED = list(dict.fromkeys(DAX40 + SMI20 + FTSE100))

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
}
