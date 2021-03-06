

# ignores row order
sameData <- function(df1, df2,
                     ingoreLeftNAs= FALSE, keySet= NULL) {
  n1 <- replyr::replyr_nrow(df1)
  n2 <- replyr::replyr_nrow(df2)
  if(n1!=n2) {
    return(FALSE)
  }
  c1 <- colnames(df1)
  c2 <- colnames(df1)
  if(length(c1)!=length(c2)) {
    return(FALSE)
  }
  ae <- all.equal(c1,c2)
  if(!is.logical(ae)) {
    return(FALSE)
  }
  if(!ae) {
    return(FALSE)
  }
  if(is.null(keySet)) {
    keySet = c1
  }
  # sorting this way can fail with NA/NaN differences and so on
  ds1COMPOSITEKEY <- do.call(paste,df1[, keySet, drop=FALSE])
  ds2COMPOSITEKEY <- do.call(paste,df2[, keySet, drop=FALSE])
  ds1 <- df1[order(ds1COMPOSITEKEY), , drop=FALSE]
  ds2 <- df1[order(ds2COMPOSITEKEY), , drop=FALSE]
  for(ci in c1) {
    v1 <- ds1[[ci]]
    v2 <- ds2[[ci]]
    # get rid of some path dependent type diffs
    if(is.factor(v1) || is.factor(v2)) {
      v1 <- as.character(v1)
      v2 <- as.character(v2)
    }
    if(is.numeric(v1) || is.numeric(v2)) {
      if(is.numeric(v1) != is.numeric(v2)) {
        return(FALSE)
      }
      v1 <- as.double(v1)
      v2 <- as.double(v2)
    }
    if(ingoreLeftNAs) {
      vIdxs <- !is.na(v1)
      v1 <- v1[vIdxs]
      v2 <- v2[vIdxs]
    }
    alle <- all.equal(v1, v2)
    if(!is.logical(alle)) {
      return(FALSE)
    }
    if(!alle) {
      return(FALSE)
    }
  }
  return(TRUE)
}

failingFrameIndices <- function(l1, l2) {
  n1 <- length(l1)
  n2 <- length(l2)
  if(n1!=n2) {
    stop("lists are different lengths")
  }
  which(vapply(seq_len(n1),
               function(i) {
                 !sameData(l1[[i]], l2[[i]])
               },
               logical(1)))
}

listsOfSameData <- function(l1, l2) {
  length(failingFrameIndices(l1, l2))<=0
}

remoteCopy <- function(my_db) {
  force(my_db)
  function(df,name) {
    replyr::replyr_copy_to(dest=my_db, df=df, name=name,
                           overwrite = TRUE, temporary = TRUE)
  }
}

runExample <- function(copyToRemote) {
  force(copyToRemote)
  dS <- data.frame(p= c(TRUE, FALSE, NA),
                  # s = NA,
                  w= 1:3,
                  x=c(NA,2,3),
                  y=factor(c(3,5,'hi')), # MySQL can't take a NA in this column
                  z=c('a','b','z'),      # MySQL can't take a NA in this column
                  stringsAsFactors=FALSE)
  # dS$q <- list(1,2,3) # can't send lists to many remote data sources (even though some produce them)
  d1 <- copyToRemote(dS, 'd1')

  print(class(d1))
  print(class(replyr::replyr_get_src(d1)))
  print(d1)
  print(paste('local:', replyr::replyr_is_local_data(d1)))
  print(paste('MySQL:', replyr::replyr_is_MySQL_data(d1)))
  print(paste('Spark:', replyr::replyr_is_Spark_data(d1)))
  d1s <- replyr::replyr_summary(d1)
  print(d1s)

  cat('\nd1 %.>% replyr::replyr_colClasses(.) \n')
  print(d1 %.>% replyr::replyr_colClasses(.))

  cat('\nd1 %.>% replyr::replyr_testCols(., is.numeric) \n')
  print(d1 %.>% replyr::replyr_testCols(., is.numeric))

  cat('\nd1 %.>% replyr::replyr_dim(.) \n')
  print(d1 %.>% replyr::replyr_dim(.))

  cat('\nd1 %.>% replyr::replyr_nrow(.) \n')
  print(d1 %.>% replyr::replyr_nrow(.))

  # mysql crashes on copyToRemote with NA values in string constants
  # https://github.com/hadley/dplyr/issues/2259
  #  and sparklyr converts them to space anyway.
  d2 <- copyToRemote(data.frame(x=c(1,2,3),y=c(3,5,NA),z=c('a','a','z')),'d2')
  print(d2)

  cat('\nd2 %.>% replyr::replyr_quantile(., "x") \n')
  print(d2 %.>% replyr::replyr_quantile(., "x"))

  cat('\nd2 %.>% replyr::replyr_summary(.) \n')
  print(d2 %.>% replyr::replyr_summary(.))

  d2b <- copyToRemote(data.frame(x=c(1,2,3),y=c(3,5,NA),z=c('a','a','z'),
                                 stringsAsFactors = FALSE),'d2b')
  print(d2b)

  cat('\nd2b %.>% replyr::replyr_quantile(., "x") \n')
  print(d2b %.>% replyr::replyr_quantile(., "x"))

  cat('\nd2b %.>% replyr::replyr_summary(.) \n')
  print(d2b %.>% replyr::replyr_summary(.))

  d3 <- copyToRemote(data.frame(x=c('a','a','b','b','c','c'),
                                y=1:6,
                                stringsAsFactors=FALSE),'d3')
  print(d3)

  ## dplyr::sample_n(d3,3) # not currently implemented for tbl_sqlite
  values <- c('a','c')
  print(values)

  cat('\nd3 %.>% replyr::replyr_filter(., "x",values,verbose=FALSE) \n')
  print(d3 %.>% replyr::replyr_filter(., "x",values,verbose=FALSE))

  cat('\nd3 %.>% replyr::replyr_inTest(., "x",values,"match",verbose=FALSE) \n')
  print(d3 %.>% replyr::replyr_inTest(., "x",values,"match",verbose=FALSE))

  d4 <- copyToRemote(data.frame(x=c(1,2,3,3)),'d4')
  print(d4)

  cat('\nd4 %.>% replyr::replyr_uniqueValues(., "x") \n')
  print(d4 %.>% replyr::replyr_uniqueValues(., "x"))

  # let example
  print("let example")
  dlet <- copyToRemote(data.frame(Sepal_Length=c(5.8,5.7),
                  Sepal_Width=c(4.0,4.4),
                  Species='setosa',
                  rank=c(1,2)),'dlet')
  mapping = list(RankColumn='rank')
  wrapr::let(
    alias=mapping,
    expr={
      dlet %.>% mutate(., RankColumn=RankColumn-1) -> dletres
    })
  print(dletres)

  # coalesce example
  print("coalesce example 1")
  dcoalesce <- copyToRemote(data.frame(year = c(2005,2007,2010),
                     count = c(6,1,NA),
                     name = c('a','b','c'),
                     stringsAsFactors = FALSE),
                     'dcoalesce')
  support <- copyToRemote(data.frame(year=2005:2010),
                          'support')
  filled <-  replyr::replyr_coalesce(dcoalesce, support,
                            fills=list(count= 0, name= '')) %.>%
    arrange(., year, name)
  print(filled)

  print("coalesce example 2")
  data <- copyToRemote(data.frame(year = c(2005,2007,2010),
                                  count = c(6,1,NA),
                                  name = c('a','b','c'),
                                  stringsAsFactors = FALSE),
                       'dcoal2')
  support <- copyToRemote(expand.grid(year=2005:2010,
                                      name= c('a','b','c','d'),
                                      stringsAsFactors = FALSE),
                          'support2')
  filled2 <-  replyr::replyr_coalesce(data, support,
                            fills=list(count=0)) %.>%
    arrange(., year, name)
  print(filled2)



  print("split re-join")
  parts <- replyr::replyr_split(data, 'year', partitionMethod = "extract")
  recovered <- dplyr::arrange(replyr::replyr_bind_rows(parts), year)
  print(recovered)

  print("gapply")
  dga <- copyToRemote(data.frame(group=c(1,1,2,2,2),
                                 order=c(.1,.2,.3,.4,.5),
                                 values=c(10,20,2,4,8)),
                      'dga')
  fn <- function(.) {
    dplyr::summarize(., cv=max(values)) }
  dgar <- dplyr::arrange(replyr::gapply(dga, 'group', fn, ocolumn='order',
                                        partitionMethod='extract',
                                        restoreGroup=TRUE),
                         group)
  print(dgar)


  print("moveValuesToColumnsQ")
  dmvtc <- copyToRemote(data.frame(
    index = c(1, 2, 3, 1, 2, 3),
    meastype = c('meas1','meas1','meas1','meas2','meas2','meas2'),
    meas = c('m1_1', 'm1_2', 'm1_3', 'm2_1', 'm2_2', 'm2_3'),
    stringsAsFactors = FALSE),
    'mvtc')
  my_db <- replyr::dplyr_src_to_db_handle(replyr::replyr_get_src(dmvtc))
  if(!is.null(my_db)) {
    ct <- cdata::buildPivotControlTableN('mvtc',
                                         columnToTakeKeysFrom= 'meastype',
                                         columnToTakeValuesFrom= 'meas',
                                         sep= '_',
                                         my_db = my_db)
    dmvtcr <- cdata::moveValuesToColumnsN('mvtc',
                                           controlTable = ct,
                                           keyColumns= 'index',
                                           my_db = my_db) %.>%
      dplyr::tbl(my_db, .)
  } else {
    dmvtcr <- cdata::pivotValuesToColumns(dmvtc,
                                          columnToTakeKeysFrom= 'meastype',
                                          columnToTakeValuesFrom= 'meas',
                                          rowKeyColumns= 'index',
                                          sep= '_')
  }
  dmvtcr <- dplyr::arrange(dmvtcr, index)
  print(dmvtcr)

  print("moveValuesToRowsQ")
  dmvtr <- copyToRemote(data.frame(
    index = c(1, 2, 3),
    info = c('a', 'b', 'c'),
    meas1 = c('m1_1', 'm1_2', 'm1_3'),
    meas2 = c('m2_1', 'm2_2', 'm2_3'),
    stringsAsFactors = FALSE),
    'mvtr')
  if(!is.null(my_db)) {
    ct <- cdata::buildUnPivotControlTable(nameForNewKeyColumn= 'meastype',
                                          nameForNewValueColumn= 'meas',
                                          columnsToTakeFrom= c('meas1','meas2'))
    dmvtrr <- cdata::moveValuesToRowsN('mvtr',
                                       controlTable = ct,
                                       columnsToCopy = c('index', 'info'),
                                       my_db = my_db) %.>%
      dplyr::tbl(my_db, .)
  } else {
    dmvtrr <- cdata::unpivotValuesToRows(dmvtr,
                                         nameForNewKeyColumn= 'meastype',
                                         nameForNewValueColumn= 'meas',
                                         columnsToTakeFrom= c('meas1','meas2'))
  }
  dmvtrr <-  dplyr::arrange(dmvtrr, index, meastype)
  print(dmvtrr)

  # pack up results for comparison
  resFrames <- list(d1s,
                    d2,
                    d2b,
                    d3,
                    d4,
                    dletres,
                    filled,
                    filled2,
                    recovered,
                    dgar,
                    dmvtcr,
                    dmvtrr
                    )

  resFrames <- lapply(resFrames, replyr::replyr_copy_from)
  resFrames
}
