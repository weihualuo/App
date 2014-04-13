

angular.module('MESSAGE', [])
  .constant('MESSAGE',
    SHARE:       '分享活动'
    COMMENT:     '发表评论'
    LOAD_FAILED: '加载失败'
    NO_MORE:     '没有更多了'
    SUBMITTING:   '正在提交...'
    UPLOADING:   '正在上传图片...'
    SUBMIT_FAILED: '提交失败'
    UPLOAD_FAILED: '上传失败'
    SHARE_OPTS:  ['新浪微博','微信朋友圈']
    STATUSES:    [ "已取消　", "已开始　", "即将开始", "正在进行", "已结束　"]
  )
  .constant('Config',
    $meta:
      imgbase: "http://houzz-imgs.stor.sinaapp.com/"
      style: []
      room: []
      location: []
    $filter:
      room:
        title: '空间'
        any:
          id: 0
          en: 'All spaces'
          cn: '所有空间'
      style:
        title: '风格'
        any:
          id: 0
          en: 'Any Style'
          cn: '所有风格'
      location:
        title: '地点'
        any:
          id: 0
          en: 'Any Area'
          cn: '全部地点'

    photos:
      filters: ['style', 'room', 'location']
      title: '照片'
    products:
      filters: ['style', 'room']
      title: '产品'
    pros:
      filters: ['location']
      title: '设计师'
    ideabooks:
      filters: ['style', 'room']
      title: '灵感集'
    advice:
      title: '建议'
    my:
      title: '我的家居'
    productDetail:
      title: '产品详情'

  )

