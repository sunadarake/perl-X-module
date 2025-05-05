
package X::DB {

    use v5.40;
    use utf8::all;
    use Moo;
    use Carp qw(croak);
    use Teng::Schema::Loader;
    use DBI;

    # Teng インスタンス
    has teng => (
        is       => 'ro',
        required => 1,
    );

    has table => (
        is       => "rw",
        required => 1,
    );

    has primary_key => (
        is       => "rw",
        required => 1,
        default  => sub { "id" },
    );

    sub connect_database( $class, $db_path, $table ) {
        say "データベースに接続します: $db_path";

        # DBディレクトリが存在しない場合は作成
        my $db_dir = $db_path;
        $db_dir =~ s|/[^/]+$||;
        if ( !-d $db_dir ) {
            say "DBディレクトリを作成します: $db_dir";
            mkdir $db_dir or die "DBディレクトリの作成に失敗しました: $db_dir ($!)";
        }

# DB接続
# @note AutoCommit => 1 にするのは奇妙に思えるが、DBD::SQLite3の仕様上正しい。
#
# @url https://perldoc.jp/docs/modules/DBD-SQLite-1.29/SQLite.pod#Transactions
# @url https://stackoverflow.com/questions/55064603/perl-dbi-sqlite-commit-or-detach-fails-when-autocommit-is-set-to-false
#
        my $dbh = DBI->connect(
            "dbi:SQLite:dbname=$db_path",
            "", "",
            {
                RaiseError     => 1,
                PrintError     => 0,
                AutoCommit     => 1,
                sqlite_unicode => 1,
            }
        ) or die $DBI::errstr;

        # Tengスキーマをロード
        my $teng = Teng::Schema::Loader->load(
            dbh       => $dbh,
            namespace => 'MyApp::DB',
        );

        say "データベース接続が完了しました";
        return $class->new( teng => $teng, table => $table );
    }

    # テーブル名を返す（サブクラスでオーバーライドする）
    sub table_name ($self) {
        croak "table_name method must be implemented in subclass"
          unless $self->table;
    }

    sub execute( $self, $sql, $binds = [] ) {

        if ( scalar(@$binds) ) {
            $self->teng->execute( $sql, $binds );

        }
        else {
            $self->teng->execute($sql);

        }
    }

    # 全てのレコードを取得する
    sub find_all ( $self, $option = {} ) {
        my $table = $self->table_name;
        my @rows  = $self->teng->search( $table, {}, $option );

        return \@rows;
    }

    # tengで createとかfindをした取得したオブジェクトでは、 $row->countなどはできないので、
    # かわりにこのメソッドで行う。
    #
    # 参考URL: http://www.omakase.org/perl/tengiterator_countplugin/
    #
    sub _rows_count ( $self, $rows ) {
        return $rows ? scalar( @{ $rows->all } ) : 0;
    }

    # IDで1件取得する
    sub find_by_id ( $self, $id ) {
        my $table = $self->table_name;
        my $pk    = $self->primary_key;
        my $row   = $self->teng->single( $table, { $pk => $id } );

        return $row;
    }

    # 条件に合致するレコードを取得する
    sub find_by ( $self, $condition ) {
        my $table = $self->table_name;
        my $row   = $self->teng->single( $table, $condition );
        return $row;
    }

    # SQLを直接実行して検索する
    sub find_by_sql ( $self, $sql, $binds = [], $option = {} ) {
        my $table = $self->table_name;
        my @rows  = $self->teng->search_by_sql( $sql, $binds, $table );
        return \@rows;
    }

    # 条件に合致するレコードを取得する
    sub where ( $self, $cond, $option = {} ) {
        my $table = $self->table_name;
        my @rows  = $self->teng->search( $table, $cond, $option );
        return \@rows;
    }

    # 1件追加する
    sub create ( $self, $data ) {
        my $table = $self->table_name;

        my $row = $self->teng->insert( $table, $data );
        return $row;
    }

    # １件追加する。 create メソッドの alias
    sub insert( $self, $data ) { return $self->create($data); }

    # 検索してなければ作成する。
    sub find_or_create( $self, $data, $cond ) {
        my $row = $self->find_by($cond);

        return $row if $row;

        return $self->create($data);
    }

    # レコードを更新する。更新したあとに、更新後の$rowを返す。
    sub update_and_find( $self, $id, $data ) {
        my $table = $self->table_name;
        my $row   = $self->teng->single( $table, { id => $id } );

        $row->update($data);
        return $row;
    }

    # レコードが存在するかをチェックする。
    sub exists( $self, $cond ) {
        my $row = $self->find_by($cond);

        if ($row) {
            return 1;
        }
        else {
            return 0;
        }
    }

    # 検索条件に一致するレコードがあれば更新、なければ作成する
    sub upsert ( $self, $data, $search_condition ) {
        my $table = $self->table_name;

        # 検索条件に一致するレコードを検索
        my $row = $self->find_by($search_condition);

        # レコードが存在する場合は更新
        if ($row) {
            my $id_val = $row->get_column( $self->primary_key );

            # 主キーを検索条件から取得して更新
            $self->update( $id_val, $data );

            # 更新後のレコードを再取得して返す
            return $self->find_by_id($id_val);
        }

        # レコードが存在しない場合は新規作成
        else {
            # 検索条件のデータも含めてレコードを作成
            my $merged_data = { %$search_condition, %$data };
            my $row         = $self->create($merged_data);

            return $row;
        }
    }

    # レコードを更新する
    sub update ( $self, $id, $data ) {
        my $table = $self->table_name;
        my $pk    = $self->primary_key;

        my $result = $self->teng->update( $table, $data, { $pk => $id } );
        return $result;

    }

    # レコードを削除する
    sub delete ( $self, $id ) {
        my $table = $self->table_name;
        my $pk    = $self->primary_key;

        my $result = $self->teng->delete( $table, { $pk => $id } );
        return $result;

    }

    # 条件に合致するレコードを削除する
    sub delete_by ( $self, $condition ) {
        my $table = $self->table_name;

        my $result = $self->teng->delete( $table, $condition );
        return $result;

    }

    sub total_count($self) {
        my @rows = $self->teng->search( $self->table_name, +{} );
        return scalar(@rows);
    }

    sub begin_trans($self) { $self->teng->txn_begin; }

    sub commit($self) { $self->teng->txn_commit; }

    sub rollback($self) { $self->teng->txn_rollback; }
}

1;

=encoding utf8

=head1 名前

X::DB - SQLiteデータベース操作のための汎用基底クラス

=head1 概略

    use X::DB;
    
    # Tengインスタンスを作成
    my $teng = X::DB->connect_database('/path/to/database.db');
    
    # 具体的なDBクラスをインスタンス化
    my $user_db = UserDB->new(teng => $teng);
    
    # レコードを取得
    my $users = $user_db->find_all();
    my $user = $user_db->find_by_id(1);

=head1 説明

このモジュールはSQLiteデータベースに対する操作を簡素化するための基底クラスを提供する。

Tengを使用してデータベース操作を行い、継承によって具体的なテーブル操作用クラスを実装できる。

トランザクション管理、CRUD操作、検索機能など基本的なデータベース操作メソッドを備えている。

=head1 クラスメソッド

=head2 connect_database

    my $teng = X::DB->connect_database('/path/to/database.db');

指定されたパスにSQLiteデータベースへの接続を確立し、Tengインスタンスを返す。

- 引数: $db_path (Str) - データベースファイルのパス
- 引数: $table (Str) - データベースを操作する table

- 戻り値: $teng (X::DB) - 設定済みのX::DBインスタンス

データベースディレクトリが存在しない場合は自動的に作成する。SQLiteに最適化された接続設定を行い、Tengスキーマをロードする。

=head1 インスタンスメソッド

=head2 table_name

    my $table = $db->table_name();

テーブル名を返す。サブクラスでオーバーライドする必要がある。

- 引数: なし
- 戻り値: $table_name (Str) - テーブル名

このメソッドをオーバーライドしない場合、例外が発生する。

=head2 primary_key

    my $pk = $db->primary_key();

主キーの名前を返す。デフォルトは'id'。必要に応じてサブクラスでオーバーライドする。

- 引数: なし
- 戻り値: $primary_key (Str) - 主キー名（デフォルト: 'id'）

=head2 find_all

    my $rows = $db->find_all(\%option);

テーブルの全レコードを取得する。

- 引数: $option (HashRef) - 検索オプション
- 戻り値: $rows (ArrayRef[Teng::Row]) - 取得した行オブジェクトの配列

=head2 _rows_count

    my $count = $db->_rows_count($rows);

行オブジェクトの配列の要素数を返す。

- 引数: $rows (Teng::Iterator) - 行オブジェクトのイテレータ
- 戻り値: $count (Int) - 行数

Tengのイテレータオブジェクトから行数を取得するための内部メソッド。

=head2 find_by_id

    my $row = $db->find_by_id($id);

IDによって1件のレコードを取得する。

- 引数: $id (Int|Str) - 主キーの値
- 戻り値: $row (Teng::Row|undef) - 取得した行オブジェクト、または見つからない場合はundef

=head2 find_by

    my $row = $db->find_by(\%condition);

条件に合致する1件のレコードを取得する。

- 引数: $condition (HashRef) - 検索条件
- 戻り値: $row (Teng::Row|undef) - 取得した行オブジェクト、または見つからない場合はundef

=head2 find_by_sql

    my $rows = $db->find_by_sql($sql, \@binds, \%option);

SQLを直接実行して検索する。

- 引数: $sql (Str) - 実行するSQL文
- 引数: $binds (ArrayRef) - SQLにバインドする値の配列
- 引数: $option (HashRef) - 検索オプション
- 戻り値: $rows (ArrayRef[Teng::Row]) - 取得した行オブジェクトの配列

=head2 where

    my $rows = $db->where(\%condition, \%option);

条件に合致するレコードを取得する。

- 引数: $condition (HashRef) - 検索条件
- 引数: $option (HashRef) - 検索オプション
- 戻り値: $rows (ArrayRef[Teng::Row]) - 取得した行オブジェクトの配列

=head2 create

    my $row = $db->create(\%data);

1件のレコードを追加する。

- 引数: $data (HashRef) - 挿入するデータ
- 戻り値: $row (Teng::Row) - 挿入した行オブジェクト

=head2 insert

    my $row = $db->insert(\%data);

1件のレコードを追加する。createメソッドのエイリアス。

- 引数: $data (HashRef) - 挿入するデータ
- 戻り値: $row (Teng::Row) - 挿入した行オブジェクト

=head2 find_or_create

    my $row = $db->find_or_create(\%data, \%condition);

条件に合致するレコードを検索し、存在しない場合は新規作成する。

- 引数: $data (HashRef) - 挿入するデータ
- 引数: $condition (HashRef) - 検索条件
- 戻り値: $row (Teng::Row) - 検索結果または新規作成した行オブジェクト

=head2 update_and_find

    my $row = $db->update_and_find($id, \%data);

レコードを更新し、更新後の行オブジェクトを返す。

- 引数: $id (Int|Str) - 更新するレコードの主キー値
- 引数: $data (HashRef) - 更新するデータ
- 戻り値: $row (Teng::Row) - 更新後の行オブジェクト

=head2 exists

    my $exists = $db->exists(\%condition);

条件に合致するレコードが存在するかを確認する。

- 引数: $condition (HashRef) - 検索条件
- 戻り値: $exists (Bool) - レコードが存在する場合は1、しない場合は0

=head2 upsert

    my $row = $db->upsert(\%data, \%search_condition);

検索条件に一致するレコードがあれば更新し、なければ新規作成する（更新または挿入）。

- 引数: $data (HashRef) - 更新または挿入するデータ
- 引数: $search_condition (HashRef) - 検索条件
- 戻り値: $row (Teng::Row) - 更新または挿入後の行オブジェクト

=head2 update

    my $result = $db->update($id, \%data);

IDを指定してレコードを更新する。

- 引数: $id (Int|Str) - 更新するレコードの主キー値
- 引数: $data (HashRef) - 更新するデータ
- 戻り値: $result (Int) - 更新された行数

=head2 delete

    my $result = $db->delete($id);

IDを指定してレコードを削除する。

- 引数: $id (Int|Str) - 削除するレコードの主キー値
- 戻り値: $result (Int) - 削除された行数

=head2 delete_by

    my $result = $db->delete_by(\%condition);

条件に合致するレコードを削除する。

- 引数: $condition (HashRef) - 削除条件
- 戻り値: $result (Int) - 削除された行数

=head2 total_count

    my $count = $db->total_count();

テーブル内の全レコード数を返す。

- 引数: なし
- 戻り値: $count (Int) - レコード総数

=head2 begin_trans

    $db->begin_trans();

トランザクションを開始する。

- 引数: なし
- 戻り値: なし

=head2 commit

    $db->commit();

トランザクションをコミットする。

- 引数: なし
- 戻り値: なし

=head2 rollback

    $db->rollback();

トランザクションをロールバックする。

- 引数: なし
- 戻り値: なし

=cut
